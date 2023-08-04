import times, macros, algorithm
import vmath, bumpy, siwin, shady, fusion/[matching, astdsl]
import gl
export vmath, bumpy, gl

type
  AnchorOffsetFrom* = enum
    start
    center
    `end`

  Anchor* = object
    obj*: UiObj
      ## if nil, anchor is disabled
    offsetFrom*: AnchorOffsetFrom
    offset*: float32
  
  Anchors* = object
    left*, right*, top*, bottom*, centerX*, centerY*: Anchor
  
  RepopsitionDirection* = enum
    parentToChild
    childToParent

  Uiobj* = ref object of RootObj
    parent* {.cursor.}: Uiobj
      ## parent of this object, that must have this object as child
      ## note: object can have no parent
    childs*: seq[owned(Uiobj)]
      ## childs that should be deleted when this object is deleted
    globalTransform*: bool
    box*: Rect
    anchors*: Anchors
  
  
  Signal* = ref object of RootObj
    sender* {.cursor.}: Uiobj


  DrawContext* = ref object
    solid: tuple[
      shader: Shader,
      transform: GlInt,
      size: GlInt,
      px: GlInt,
      radius: GlInt,
      color: GlInt,
    ]
    image: tuple[
      shader: Shader,
      transform: GlInt,
      size: GlInt,
      px: GlInt,
      radius: GlInt,
    ]
    icon: tuple[
      shader: Shader,
      transform: GlInt,
      size: GlInt,
      px: GlInt,
      radius: GlInt,
      color: GlInt,
    ]
    rectShadow: tuple[
      shader: Shader,
      transform: GlInt,
      size: GlInt,
      px: GlInt,
      radius: GlInt,
      blurRadius: GlInt,
      color: GlInt,
    ]

    rect: Shape

    px, wh: Vec2

  
  WindowEvent* = ref object of Signal
    event*: ref AnyWindowEvent
    handled*: bool
  
  #--- Basic Components ---


  UiWindow* = ref object of Uiobj
    siwinWindow*: Window
    ctx*: DrawContext
    clearColor*: Vec4


  UiRect* = ref object of Uiobj
    color*: Vec4 = vec4(0, 0, 0, 1)
    radius*: float32
  

  UiRectShadow* = ref object of Uirect
    blurRadius*: float32



#----- Uiobj -----



method draw*(obj: Uiobj, ctx: DrawContext) {.base.} =
  for x in obj.childs: draw(x, ctx)


proc parentWindow*(obj: Uiobj): Window =
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return nil
    if obj of UiWindow: return obj.UiWindow.siwinWindow
    obj = obj.parent


proc posToLocal*(pos: Vec2, obj: Uiobj): Vec2 =
  result = pos
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return
    result -= obj.box.xy
    if obj.globalTransform: return
    obj = obj.parent

proc posToGlobal*(pos: Vec2, obj: Uiobj): Vec2 =
  result = pos
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return
    result += obj.box.xy
    if obj.globalTransform: return
    obj = obj.parent


proc posToObject*(fromObj, toObj: Uiobj, pos: Vec2): Vec2 =
  pos.posToGlobal(fromObj).posToLocal(toObj)


method recieve*(obj: Uiobj, signal: Signal) {.base.} =
  if signal of WindowEvent:
    template handlePositionalEvent(ev) =
      let e {.cursor.} = (ref ev)signal.WindowEvent.event
      for x in obj.childs.reversed:
        let pos = x.box.xy.posToGlobal(x)
        if e.window.mouse.pos.x.float32 in pos.x..(pos.x + x.box.w) and e.window.mouse.pos.y.float32 in pos.y..(pos.y + x.box.h):
          x.recieve(signal)
    
    if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
      handlePositionalEvent MouseButtonEvent
    
    elif signal of WindowEvent and signal.WindowEvent.event of ClickEvent:
      handlePositionalEvent ClickEvent
    
    elif signal of WindowEvent and signal.WindowEvent.event of MouseMoveEvent:
      handlePositionalEvent MouseMoveEvent

    else:
      for x in obj.childs:
        x.recieve(signal)


proc pos*(anchor: Anchor, isY: bool): Vec2 =
  assert anchor.obj != nil
  let p = case anchor.offsetFrom
  of start:
    anchor.offset
  of `end`:
    if isY:
      anchor.obj.box.h - anchor.offset
    else:
      anchor.obj.box.w - anchor.offset
  of center:
    if isY:
      anchor.obj.box.h / 2 - anchor.offset
    else:
      anchor.obj.box.w / 2 - anchor.offset
  if isY: vec2(0, p).posToGlobal(anchor.obj)
  else: vec2(p, 0).posToGlobal(anchor.obj)

#--- Reposition ---

method reposition*(obj: Uiobj, direction: RepopsitionDirection = parentToChild) {.base.}

proc broadcastReposition*(obj: Uiobj, direction: RepopsitionDirection) =
  for x in obj.childs: reposition(x, direction)

proc anchorReposition*(obj: Uiobj) =
  # x and w
  if obj.anchors.left.obj != nil:
    obj.box.x = obj.anchors.left.pos(isY=false).posToLocal(obj.parent).x
  
  if obj.anchors.right.obj != nil:
    if obj.anchors.left.obj != nil:
      obj.box.w = obj.anchors.right.pos(isY=false).posToLocal(obj.parent).x - obj.box.x
    else:
      obj.box.x = obj.anchors.right.pos(isY=false).posToLocal(obj.parent).x - obj.box.w
  
  if obj.anchors.centerX.obj != nil:
    obj.box.x = obj.anchors.right.pos(isY=false).posToLocal(obj.parent).x - obj.box.w / 2

  # y and h
  if obj.anchors.top.obj != nil:
    obj.box.y = obj.anchors.top.pos(isY=true).posToLocal(obj.parent).y
  
  if obj.anchors.bottom.obj != nil:
    if obj.anchors.top.obj != nil:
      obj.box.h = obj.anchors.bottom.pos(isY=true).posToLocal(obj.parent).y - obj.box.y
    else:
      obj.box.y = obj.anchors.bottom.pos(isY=true).posToLocal(obj.parent).y - obj.box.h
  
  if obj.anchors.centerY.obj != nil:
    obj.box.y = obj.anchors.bottom.pos(isY=true).posToLocal(obj.parent).y - obj.box.h / 2

method reposition*(obj: Uiobj, direction: RepopsitionDirection = parentToChild) {.base.} =
  anchorReposition obj
  broadcastReposition obj, direction

#--- Anchors ---

proc fillHorizontal*(anchors: var Anchors, obj: Uiobj, margin: float32 = 0) =
  anchors.left = Anchor(obj: obj, offset: margin)
  anchors.right = Anchor(obj: obj, offsetFrom: `end`, offset: margin)

proc fillVertical*(anchors: var Anchors, obj: Uiobj, margin: float32 = 0) =
  anchors.top = Anchor(obj: obj, offset: margin)
  anchors.bottom = Anchor(obj: obj, offsetFrom: `end`, offset: margin)

proc centerIn*(anchors: var Anchors, obj: Uiobj, offset: Vec2 = vec2(), xCenterAt: AnchorOffsetFrom = center, yCenterAt: AnchorOffsetFrom = center) =
  anchors.centerX = Anchor(obj: obj, offsetFrom: xCenterAt, offset: offset.x)
  anchors.centerY = Anchor(obj: obj, offsetFrom: yCenterAt, offset: offset.y)

proc fill*(anchors: var Anchors, obj: Uiobj, margin: float32 = 0) =
  anchors.fillHorizontal(obj, margin)
  anchors.fillVertical(obj, margin)


method addChild*(parent: Uiobj, child: Uiobj) {.base.} =
  assert child.parent == nil
  child.parent = parent
  parent.childs.add child


macro super*[T: Uiobj](obj: T): auto =
  var t = obj.getTypeImpl
  case t
  of RefTy[@sym is Sym()]:
    t = sym.getImpl
  case t
  of TypeDef[_, _, ObjectTy[_, OfInherit[@sup], .._]]:
    return buildAst(dotExpr):
      obj
      sup
  else: error("unexpected type impl", obj)


#----- DrawContext -----



proc mat4(x: Mat2): Mat4 = discard
  ## note: this function exists in Glsl, but do not in vmath


proc passTransform(ctx: DrawContext, shader: tuple, pos = vec2(), size = vec2(10, 10), angle: float32 = 0) =
  shader.transform.uniform =
    translate(vec3(ctx.px*(vec2(pos.x, -pos.y) - ctx.wh), 0)) *
    rotate(float32 angle.float * Pi / 180, vec3(0, 0, 1))
  shader.size.uniform = size
  shader.px.uniform = ctx.px

var tex: Uniform[Sampler2d]  # workaround shady#9

proc newDrawContext*: DrawContext =
  new result
  # compile shaders and init shapes

  proc transformation(glpos: var Vec4, pos: var Vec2, size, px, ipos: Vec2, transform: Mat4) =
    let scale = vec2(px.x * size.x, px.y * -size.y)
    glpos = transform * mat2(scale.x, 0, 0, scale.y).mat4 * vec4(ipos, vec2(0, 1))
    pos = vec2(ipos.x * size.x, ipos.y * size.y)

  proc roundRect(pos, size: Vec2, radius: float32): float32 =
    if radius == 0: return 1
    
    if pos.x < radius and pos.y < radius:
      let d = length(pos - vec2(radius, radius))
      return (radius - d + 0.5).max(0).min(1)
    
    elif pos.x > size.x - radius and pos.y < radius:
      let d = length(pos - vec2(size.x - radius, radius))
      return (radius - d + 0.5).max(0).min(1)
    
    elif pos.x < radius and pos.y > size.y - radius:
      let d = length(pos - vec2(radius, size.y - radius))
      return (radius - d + 0.5).max(0).min(1)
    
    elif pos.x > size.x - radius and pos.y > size.y - radius:
      let d = length(pos - vec2(size.x - radius, size.y - radius))
      return (radius - d + 0.5).max(0).min(1)

    return 1

  proc distanceRoundRect(pos, size: Vec2, radius: float32, blurRadius: float32): float32 =
    if pos.x < radius + blurRadius and pos.y < radius + blurRadius:
      let d = length(pos - vec2(radius + blurRadius, radius + blurRadius))
      result = ((radius + blurRadius - d) / blurRadius).max(0).min(1)
    
    elif pos.x > size.x - radius - blurRadius and pos.y < radius + blurRadius:
      let d = length(pos - vec2(size.x - radius - blurRadius, radius + blurRadius))
      result = ((radius + blurRadius - d) / blurRadius).max(0).min(1)
    
    elif pos.x < radius + blurRadius and pos.y > size.y - radius - blurRadius:
      let d = length(pos - vec2(radius + blurRadius, size.y - radius - blurRadius))
      result = ((radius + blurRadius - d) / blurRadius).max(0).min(1)
    
    elif pos.x > size.x - radius - blurRadius and pos.y > size.y - radius - blurRadius:
      let d = length(pos - vec2(size.x - radius - blurRadius, size.y - radius - blurRadius))
      result = ((radius + blurRadius - d) / blurRadius).max(0).min(1)
    
    elif pos.x < blurRadius:
      result = (pos.x / blurRadius).max(0).min(1)

    elif pos.y < blurRadius:
      result = (pos.y / blurRadius).max(0).min(1)
    
    elif pos.x > size.x - blurRadius:
      result = ((size.x - pos.x) / blurRadius).max(0).min(1)

    elif pos.y > size.y - blurRadius:
      result = ((size.y - pos.y) / blurRadius).max(0).min(1)
    
    else:
      result = 1
    
    result *= result


  proc solidVert(
    gl_Position: var Vec4,
    pos: var Vec2,
    ipos: Vec2,
    transform: Uniform[Mat4],
    size: Uniform[Vec2],
    px: Uniform[Vec2],
  ) =
    transformation(gl_Position, pos, size, px, ipos, transform)

  proc solidFrag(
    glCol: var Vec4,
    pos: Vec2,
    radius: Uniform[float],
    size: Uniform[Vec2],
    color: Uniform[Vec4],
  ) =
    glCol = vec4(color.rgb * color.a, color.a) * roundRect(pos, size, radius)

  result.solid.shader = newShader {GlVertexShader: solidVert.toGLSL("330 core"), GlFragmentShader: solidFrag.toGLSL("330 core")}
  result.solid.transform = result.solid.shader["transform"]
  result.solid.size = result.solid.shader["size"]
  result.solid.px = result.solid.shader["px"]
  result.solid.radius = result.solid.shader["radius"]
  result.solid.color = result.solid.shader["color"]


  proc imageVert(
    gl_Position: var Vec4,
    pos: var Vec2,
    uv: var Vec2,
    ipos: Vec2,
    transform: Uniform[Mat4],
    size: Uniform[Vec2],
    px: Uniform[Vec2],
  ) =
    transformation(gl_Position, pos, size, px, ipos, transform)
    uv = ipos

  proc imageFrag(
    glCol: var Vec4,
    pos: Vec2,
    uv: Vec2,
    radius: Uniform[float],
    size: Uniform[Vec2],
  ) =
    let color = tex.texture(uv)
    glCol = vec4(color.rgb, color.a) * roundRect(pos, size, radius)

  result.image.shader = newShader {GlVertexShader: imageVert.toGlsl("330 core"), GlFragmentShader: imageFrag.toGlsl("330 core")}
  result.image.transform = result.image.shader["transform"]
  result.image.size = result.image.shader["size"]
  result.image.px = result.image.shader["px"]
  result.image.radius = result.image.shader["radius"]


  proc iconFrag(
    glCol: var Vec4,
    pos: Vec2,
    uv: Vec2,
    radius: Uniform[float],
    size: Uniform[Vec2],
    color: Uniform[Vec4],
  ) =
    let col = tex.texture(uv)
    glCol = vec4(color.rgb * color.a, color.a) * col.a * roundRect(pos, size, radius)

  result.icon.shader = newShader {GlVertexShader: imageVert.toGlsl("330 core"), GlFragmentShader: iconFrag.toGlsl("330 core")}
  result.icon.transform = result.icon.shader["transform"]
  result.icon.size = result.icon.shader["size"]
  result.icon.px = result.icon.shader["px"]
  result.icon.radius = result.icon.shader["radius"]
  result.icon.color = result.icon.shader["color"]


  proc rectShadowVert(
    gl_Position: var Vec4,
    pos: var Vec2,
    ipos: Vec2,
    transform: Uniform[Mat4],
    size: Uniform[Vec2],
    px: Uniform[Vec2],
  ) =
    transformation(gl_Position, pos, size, px, ipos, transform)

  proc rectShadowFrag(
    glCol: var Vec4,
    pos: Vec2,
    radius: Uniform[float],
    blurRadius: Uniform[float],
    size: Uniform[Vec2],
    color: Uniform[Vec4],
  ) =
    glCol = vec4(color.rgb * color.a, color.a) * distanceRoundRect(pos, size, radius, blurRadius)

  result.rectShadow.shader = newShader {GlVertexShader: rectShadowVert.toGLSL("330 core"), GlFragmentShader: rectShadowFrag.toGLSL("330 core")}
  result.rectShadow.transform = result.rectShadow.shader["transform"]
  result.rectShadow.size = result.rectShadow.shader["size"]
  result.rectShadow.px = result.rectShadow.shader["px"]
  result.rectShadow.radius = result.rectShadow.shader["radius"]
  result.rectShadow.blurRadius = result.rectShadow.shader["blurRadius"]
  result.rectShadow.color = result.rectShadow.shader["color"]


  result.rect = newShape(
    [
      vec2(0, 1),   # top left
      vec2(0, 0),   # bottom left
      vec2(1, 0),   # bottom right
      vec2(1, 1),   # top right
    ],
    [
      0'u32, 1, 2,
      2, 3, 0,
    ]
  )


proc updateSizeRender(ctx: DrawContext, size: IVec2) =
  # update size
  ctx.px = vec2(2'f32 / size.x.float32, 2'f32 / size.y.float32)
  ctx.wh = ivec2(size.x, -size.y).vec2 / 2


proc drawRect*(ctx: DrawContext, pos: Vec2, size: Vec2, col: Vec4, radius: float32, blend: bool) =
  # draw rect
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.solid.shader
  ctx.passTransform(ctx.solid, pos=pos, size=size)
  ctx.solid.radius.uniform = radius
  ctx.solid.color.uniform = col
  draw ctx.rect
  if blend: glDisable(GlBlend)

proc drawImage*(ctx: DrawContext, pos: Vec2, size: Vec2, tex: GlUint, radius: float32, blend: bool) =
  # draw image
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.image.shader
  ctx.passTransform(ctx.image, pos=pos, size=size)
  ctx.image.radius.uniform = radius
  glBindTexture(GlTexture2d, tex)
  draw ctx.rect
  glBindTexture(GlTexture2d, 0)
  if blend: glDisable(GlBlend)

proc drawIcon*(ctx: DrawContext, pos: Vec2, size: Vec2, tex: GlUint, col: Vec4, radius: float32, blend: bool) =
  # draw image (with solid color)
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.icon.shader
  ctx.passTransform(ctx.icon, pos=pos, size=size)
  ctx.icon.radius.uniform = radius
  ctx.icon.color.uniform = col
  glBindTexture(GlTexture2d, tex)
  draw ctx.rect
  glBindTexture(GlTexture2d, 0)
  if blend: glDisable(GlBlend)

proc drawShadowRect*(ctx: DrawContext, pos: Vec2, size: Vec2, col: Vec4, radius: float32, blend: bool, blurRadius: float32) =
  # draw rect
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.rectShadow.shader
  ctx.passTransform(ctx.rectShadow, pos=pos, size=size)
  ctx.rectShadow.radius.uniform = radius
  ctx.rectShadow.color.uniform = col
  ctx.rectShadow.blurRadius.uniform = blurRadius
  draw ctx.rect
  if blend: glDisable(GlBlend)



#----- Basic Components -----



method draw*(rect: UiRect, ctx: DrawContext) =
  ctx.drawRect(rect.box.xy.posToGlobal(rect.parent), rect.box.wh, rect.color, rect.radius, rect.color.a != 1 or rect.radius != 0)
  procCall draw(rect.Uiobj, ctx)


method draw*(rect: UiRectShadow, ctx: DrawContext) =
  ctx.drawShadowRect(rect.box.xy.posToGlobal(rect.parent), rect.box.wh, rect.color, rect.radius, true, rect.blurRadius)
  procCall draw(rect.Uiobj, ctx)


method draw*(win: UiWindow, ctx: DrawContext) =
  glClearColor(win.clearColor.r, win.clearColor.g, win.clearColor.b, win.clearColor.a)
  glClear(GlColorBufferBit or GlDepthBufferBit)
  procCall draw(win.Uiobj, ctx)


method recieve*(this: UiWindow, signal: Signal) =
  if signal of WindowEvent and signal.WindowEvent.event of ResizeEvent:
    let e = (ref ResizeEvent)signal.WindowEvent.event
    this.box.wh = e.size.vec2
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    this.ctx.updateSizeRender(e.size)
    reposition this

  if signal of WindowEvent and signal.WindowEvent.event of RenderEvent:
    draw(this, this.ctx)

  procCall this.super.recieve(signal)


proc setupEventsHandling*(win: UiWindow) =
  proc toRef[T](e: T): ref AnyWindowEvent =
    result = (ref T)()
    (ref T)(result)[] = e

  win.siwinWindow.eventsHandler = WindowEventsHandler(
    onClose:       proc(e: CloseEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onRender:      proc(e: RenderEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onTick:        proc(e: TickEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onResize:      proc(e: ResizeEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onWindowMove:  proc(e: WindowMoveEvent) = win.recieve(WindowEvent(event: e.toRef)),

    onFocusChanged:       proc(e: FocusChangedEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onFullscreenChanged:  proc(e: FullscreenChangedEvent) = win.recieve(WindowEvent(event: e.toRef)),

    onMouseMove:    proc(e: MouseMoveEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onMouseButton:  proc(e: MouseButtonEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onScroll:       proc(e: ScrollEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onClick:        proc(e: ClickEvent) = win.recieve(WindowEvent(event: e.toRef)),

    onKey:   proc(e: KeyEvent) = win.recieve(WindowEvent(event: e.toRef)),
    onTextInput:  proc(e: TextInputEvent) = win.recieve(WindowEvent(event: e.toRef)),
  )

proc newUiWindow*(siwinWindow: Window): UiWindow =
  result = UiWindow(siwinWindow: siwinWindow)
  loadExtensions()
  result.setupEventsHandling
  result.ctx = newDrawContext()



#----- Macro -----



macro makeLayout*(obj: Uiobj, body: untyped) =
  proc impl(parent: NimNode, obj: NimNode, body: NimNode): NimNode =
    buildAst:
      blockStmt:
        genSym(nskLabel, "initializationBlock")
        stmtList:
          letSection:
            identDefs(pragmaExpr(ident "parent", pragma ident "used"), empty(), parent)
            identDefs(pragmaExpr(ident "this", pragma ident "used"), empty(), obj)
          
          proc checkCtor(ctor: NimNode): bool =
            if ctor == ident "root": warning("adding root to itself causes recursion", ctor)
            if ctor == ident "this": warning("adding this to itself causes recursion", ctor)
            if ctor == ident "parent": warning("adding parent to itself causes recursion", ctor)

          for x in body:
            case x
            of Prefix[Ident(strVal: "-"), @ctor]:
              discard checkCtor ctor
              call(bindSym"addChild", ident "this", ctor)
            of Prefix[Ident(strVal: "-"), @ctor, @body is StmtList()]:
              discard checkCtor ctor
              let s = genSym(nskLet)
              letSection:
                identDefs(s, empty(), ctor)
              call(bindSym"addChild", ident "this", s)
              impl(ident "this", s, body)
            of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s]:
              discard checkCtor ctor
              letSection:
                identDefs(s, empty(), ctor)
              call(bindSym"addChild", ident "this", s)
            of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s, @body is StmtList()]:
              discard checkCtor ctor
              letSection:
                identDefs(s, empty(), ctor)
              call(bindSym"addChild", ident "this", s)
              impl(ident "this", s, body)
            else: x

  buildAst:
    blockStmt:
      genSym(nskLabel, "makeLayoutBlock")
      stmtList:
        letSection:
          identDefs(pragmaExpr(ident "root", pragma ident "used"), empty(), obj)
        impl(nnkDotExpr.newTree(ident "root", ident "parent"), ident "root", body)
