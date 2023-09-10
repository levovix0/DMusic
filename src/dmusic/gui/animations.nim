import times, std/importutils, strutils
import imageman, siwin
import ./uibase

privateAccess Event

let
  linearInterpolation* = proc(x: float): float = x
  outSquareInterpolation* = proc(x: float): float = x * x
  outQubicInterpolation* = proc(x: float): float = x * x * x
  inSquareInterpolation* = proc(x: float): float = 1 - (x - 1) * (x - 1)
  inQubicInterpolation* = proc(x: float): float = 1 + (x - 1) * (x - 1) * (x - 1)

type
  Animation*[T] = ref object
    eventHandler: EventHandler
    enabled*: Property[bool] = true.property
    running*: Property[bool]
    duration*: Property[Duration]
    action*: proc(x: T)
    interpolation*: Property[proc(x: float): float]
    a, b*: Property[T]
    loop*: Property[bool]
    ended*: Event[void]

    currentTime*: Property[Duration]
  
  Animator* = ref object of Uiobj
    onTick*: Event[Duration]
  

func interpolate*[T: enum | bool](a, b: T, x: float): T =
  # note: x can be any number, not just 0..1
  if x >= 1: b
  else: a

func interpolate*[T: SomeInteger](a, b: T, x: float): T =
  a + ((b - a).float * x).round.T

func interpolate*[T: SomeFloat](a, b: T, x: float): T =
  a + ((b - a).float * x).T

func interpolate*[T: array](a, b: T, x: float): T =
  for i, v in result.mpairs:
    v = interpolate(a[i], b[i], x)

func interpolate*[T: object | tuple](a, b: T, x: float): T =
  for i, y in result.fieldPairs:
    for j, a, b in fieldPairs(a, b):
      when i == j:
        y = interpolate(a, b, x)


# --- be compatible with makeLayout API ---
proc parentAnimator*(obj: Uiobj): Animator =
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return nil
    if obj of Animator: return obj.Animator
    obj = obj.parent

template withAnimator*(obj: UiObj, animVar: untyped, body: untyped) =
  proc bodyProc(animVar {.inject.}: Animator) =
    body
  let anim = obj.parentAnimator
  if anim != nil:
    bodyProc(anim)
  obj.onSignal.connect obj.eventHandler, proc(e: Signal) =
    if e of ParentChanged and e.ParentChanged.newParentInTree of Animator:
      bodyProc(e.ParentChanged.newParentInTree.Animator)

proc init*(a: Animation) = discard
proc initIfNeeded*(a: Animation) = discard

proc currentValue*[T](a: Animation[T]): T =
  if a.duration != DurationZero:
    let f =
      if a.interpolation[] == nil: linearInterpolation
      else: a.interpolation[]
    interpolate(a.a[], a.b[], f(a.currentTime[].inMicroseconds.float / a.duration.inMicroseconds.float))
  else:
    a.a[]

proc addChild*[T](obj: Uiobj, a: Animation[T]) =
  proc act =
    if a.enabled[] and a.action != nil and a.duration != DurationZero:
      a.action(a.currentValue)
      redraw obj

  proc tick(deltaTime: Duration) =
    if a.enabled[] and a.running[]:
      let time = a.currentTime[] + deltaTime
      a.currentTime[] =
        if time < DurationZero: DurationZero
        elif time > a.duration[]:
          if not a.loop[]:
            a.running[] = false
            a.ended.emit()
            a.duration[]
          else:
            a.ended.emit()
            initDuration(
              seconds = if a.duration.inSeconds != 0: time.inSeconds mod a.duration.inSeconds else: 0,
              nanoseconds = if a.duration.inNanoseconds != 0: time.inNanoseconds mod a.duration.inNanoseconds mod 1_000_000_000 else: 0,
            )
        else: time
  
  a.currentTime.changed.connectTo a: act()
  a.enabled.changed.connectTo a: act()
  a.a.changed.connectTo a: act()
  a.b.changed.connectTo a: act()
  a.interpolation.changed.connectTo a: act()
  a.duration.changed.connectTo a: act()

  obj.withWindow win:
    win.onTick.connectTo a, args: tick(args.deltaTime)

  obj.withAnimator anim:
    anim.onTick.connectTo a, args: tick(args)

proc start*(a: Animation) =
  a.currentTime[] = DurationZero
  a.running[] = true

template animation*[T](val: T): Animation[T] =
  Animation[T](action: proc(x: T) = val = x)


proc transitionImpl*[T](a: Animation[T], prop: var AnyProperty[T], dur: Duration) =
  prop.changed.emitCurrIdx = prop.changed.connected[].len


proc `'s`*(lit: cstring): Duration =
  let lit = ($lit).parseFloat
  initDuration(seconds = lit.int64, nanoseconds = ((lit - lit.int64.float) * 1_000_000_000).int64)
proc `'ms`*(lit: cstring): Duration =
  let lit = ($lit).parseFloat
  initDuration(milliseconds = lit.int64, nanoseconds = ((lit - lit.int64.float) * 1_000_000).int64)


template transition*[T](prop: var AnyProperty[T], dur: Duration): Animation[T] =
  bind transitionImpl
  let a = Animation[T](
    action: (proc(x: T) =
      prop{} = x
      prop.changed.emit(x, 1)
    ),
    duration: dur.property
  )
  a.a{} = prop.unsafeVal
  prop.changed.insertConnection a.eventHandler, proc(v: T) =
    a.a{} = a.currentValue
    a.b{} = v
    transitionImpl(a, prop, dur)
    start a
  a


when isMainModule:
  import ./globalShortcut

  let animator = newOpenglWindow(size = ivec2(300, 40)).newUiWindow
  animator.makeLayout:
    - newUiRect() as rect:
      this.box.w = 40
      this.box.h = 40
      this.color[] = color(1, 1, 1)

      var boxX = 10'f32.property
      this.bindingValue this.box.x: boxX[]

      - boxX.transition(0.4's):
        this.interpolation[] = inQubicInterpolation

      - globalShortcut({Key.a}, exact=false):
        this.activated.connectTo root:
          boxX[] = 10

      - globalShortcut({Key.d}, exact=false):
        this.activated.connectTo root:
          boxX[] = root.box.w - 10 - rect.box.w
    
      # - animation(this.box.x):
      #   this.duration[] = initDuration(seconds = 1)
      #   this.a[] = 100
      #   this.b[] = 1000
      #   this.loop[] = true
      #   this.interpolation[] = outSquareInterpolation
      #   this.ended.connectTo this:
      #     let a = this.a[]
      #     this.a[] = this.b[]
      #     this.b[] = a
      #   start this
  
  run animator.siwinWindow
