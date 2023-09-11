import times, macros, algorithm, tables, unicode
import vmath, bumpy, siwin, shady, fusion/[matching, astdsl], pixie
import gl, events, properties
import imageman except Rect, color, Color
export vmath, bumpy, gl, pixie, matching, events, properties
export imageman except Rect

type
  Col* = pixie.Color

  AnchorOffsetFrom = enum
    start
    center
    `end`

  Anchor* = object
    obj: UiObj
      ## if nil, anchor is disabled
    offsetFrom: AnchorOffsetFrom
    offset: float32
    eventHandler: EventHandler
  
  Anchors = object
    left, right, top, bottom, centerX, centerY: Anchor
  
  Visibility* = enum
    visible
    hidden
    hiddenTree
    collapsed
  
  
  Signal* = ref object of RootObj
    sender* {.cursor.}: Uiobj
  
  Uiobj* {.acyclic.} = ref object of RootObj
    eventHandler*: EventHandler
    
    parent* {.cursor.}: Uiobj
      ## parent of this object, that must have this object as child
      ## note: object can have no parent
    childs*: seq[owned(Uiobj)]
      ## childs that should be deleted when this object is deleted
    
    globalTransform*: Property[bool]
    x*, y*, w*, h*: Property[float32]
    visibility*: Property[Visibility]
    
    onSignal*: Event[Signal]
    
    initialized*: bool
    attachedToWindow*: bool
    
    anchors: Anchors


  #--- Signals ---

  SubtreeSignal* = ref object of Signal
    ## signal sends to all childs recursively (by default)
  
  AttachedToWindow* = ref object of SubtreeSignal
    window*: UiWindow

  ParentChanged* = ref object of SubtreeSignal
    newParentInTree*: Uiobj
  
  WindowEvent* = ref object of SubtreeSignal
    event*: ref AnyWindowEvent
    handled*: bool
    fake*: bool
  
  GetActiveCursor* = ref object of SubtreeSignal
    cursor*: ref Cursor
  
  VisibilityChanged* = ref object of SubtreeSignal
    visibility*: Visibility
  
  
  #--- Basic Components ---

  UiWindow* = ref object of Uiobj
    siwinWindow*: Window
    ctx*: DrawContext
    clearColor*: Col
    onTick*: Event[TickEvent]


  UiRect* = ref object of Uiobj
    color*: Property[Col] = color(0, 0, 0).property
    radius*: Property[float32]
    angle*: Property[float32]
  

  UiImage* = ref object of Uiobj
    radius*: Property[float32]
    blend*: Property[bool] = true.property
    tex: Textures
    imageWh*: Property[IVec2]
    angle*: Property[float32]

  UiIcon* = ref object of UiImage
    color*: Property[Col] = color(0, 0, 0).property


  UiRectShadow* = ref object of UiRect
    blurRadius*: Property[float32]
  

  UiClipRect* = ref object of Uiobj
    radius*: Property[float32]
    angle*: Property[float32]
    fbo: FrameBuffers
    tex: Textures
    prevSize: IVec2
  

  UiText* = ref object of Uiobj
    text*: Property[string]
    font*: Property[Font]
    bounds*: Property[Vec2]
    hAlign*: Property[HorizontalAlignment]
    vAlign*: Property[VerticalAlignment]
    wrap*: Property[bool] = true.property
    angle*: Property[float32]
    color*: Property[Col] = color(0, 0, 0).property

    arrangement*: Property[Arrangement]
    roundPositionOnDraw*: Property[bool] = true.property
    tex: Textures


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
    frameBufferHierarchy: seq[tuple[fbo: GlUint, size: IVec2]]
  
  BindingKind = enum
    bindProperty
    bindValue
    bindProc
  
  HasEventHandler* = concept x
    x.eventHandler is EventHandler


proc vec4*(color: Col): Vec4 =
  vec4(color.r, color.g, color.b, color.a)

proc color*(v: Vec4): Col =
  Col(r: v.x, g: v.y, b: v.z, a: v.w)

proc round*(v: Vec2): Vec2 =
  vec2(round(v.x), round(v.y))


#* ------------- Uiobj ------------- *#


proc xy*(obj: Uiobj): CustomProperty[Vec2] =
  CustomProperty[Vec2](
    get: proc(): Vec2 = vec2(obj.x[], obj.y[]),
    set: proc(v: Vec2) = obj.x[] = v.x; obj.y[] = v.y,
  )

proc wh*(obj: Uiobj): CustomProperty[Vec2] =
  CustomProperty[Vec2](
    get: proc(): Vec2 = vec2(obj.w[], obj.h[]),
    set: proc(v: Vec2) = obj.w[] = v.x; obj.h[] = v.y,
  )


method draw*(obj: Uiobj, ctx: DrawContext) {.base.} =
  if obj.visibility notin {hiddenTree, collapsed}:
    for x in obj.childs: draw(x, ctx)


proc parentUiWindow*(obj: Uiobj): UiWindow =
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return nil
    if obj of UiWindow: return obj.UiWindow
    obj = obj.parent

proc parentWindow*(obj: Uiobj): Window =
  let uiWin = obj.parentUiWindow
  if uiWin != nil: uiWin.siwinWindow
  else: nil

proc redraw*(obj: Uiobj) =
  let win = obj.parentWindow
  if win != nil: redraw win


proc posToLocal*(pos: Vec2, obj: Uiobj): Vec2 =
  result = pos
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return
    result -= obj.xy[]
    if obj.globalTransform: return
    obj = obj.parent

proc posToGlobal*(pos: Vec2, obj: Uiobj): Vec2 =
  result = pos
  var obj {.cursor.} = obj
  while true:
    if obj == nil: return
    result += obj.xy[]
    if obj.globalTransform: return
    obj = obj.parent


proc posToObject*(fromObj, toObj: Uiobj, pos: Vec2): Vec2 =
  pos.posToGlobal(fromObj).posToLocal(toObj)


method recieve*(obj: Uiobj, signal: Signal) {.base.} =
  if signal of AttachedToWindow:
    obj.attachedToWindow = true

  obj.onSignal.emit signal

  if signal of SubtreeSignal:
    for x in obj.childs:
      x.recieve(signal)


proc pos*(anchor: Anchor, isY: bool): Vec2 =
  assert anchor.obj != nil
  let p = case anchor.offsetFrom
  of start:
    if isY:
      if anchor.obj.visibility == collapsed and anchor.obj.anchors.top.obj == nil and anchor.obj.anchors.bottom.obj != nil:
        anchor.obj.h[] + anchor.offset
      else:
        anchor.offset
    else:
      if anchor.obj.visibility == collapsed and anchor.obj.anchors.left.obj == nil and anchor.obj.anchors.right.obj != nil:
        anchor.obj.w[] + anchor.offset
      else:
        anchor.offset
  of `end`:
    if isY:
      if anchor.obj.visibility == collapsed and anchor.obj.anchors.top.obj != nil and anchor.obj.anchors.bottom.obj == nil:
        anchor.offset
      else:
        anchor.obj.h[] + anchor.offset
    else:
      if anchor.obj.visibility == collapsed and anchor.obj.anchors.left.obj != nil and anchor.obj.anchors.right.obj == nil:
        anchor.offset
      else:
        anchor.obj.w[] + anchor.offset
  of center:
    if isY:
      if anchor.obj.visibility == collapsed:
        if anchor.obj.anchors.top.obj == nil and anchor.obj.anchors.bottom.obj != nil:
          anchor.obj.h[] + anchor.offset
        else:
          anchor.offset
      else:
        anchor.obj.h[] / 2 + anchor.offset
    else:
      if anchor.obj.visibility == collapsed:
        if anchor.obj.anchors.left.obj == nil and anchor.obj.anchors.right.obj != nil:
          anchor.obj.w[] + anchor.offset
        else:
          anchor.offset
      else:
        anchor.obj.w[] / 2 + anchor.offset

  if isY: vec2(0, p).posToGlobal(anchor.obj)
  else: vec2(p, 0).posToGlobal(anchor.obj)


#--- Events connection ---

template connectTo*[T](s: var Event[T], obj: HasEventHandler, body: untyped) =
  connect s, obj.eventHandler, proc(e {.inject.}: T) =
    body

template connectTo*(s: var Event[void], obj: HasEventHandler, body: untyped) =
  connect s, obj.eventHandler, proc() =
    body

template connectTo*[T](s: var Event[T], obj: HasEventHandler, argname: untyped, body: untyped) =
  connect s, obj.eventHandler, proc(argname {.inject.}: T) =
    body

template connectTo*(s: var Event[void], obj: HasEventHandler, argname: untyped, body: untyped) =
  connect s, obj.eventHandler, proc() =
    body


#--- Reposition ---

proc applyAnchors*(obj: Uiobj) =
  # x and w
  if obj.anchors.left.obj != nil:
    obj.x[] = obj.anchors.left.pos(isY=false).posToLocal(obj.parent).x
  
  if obj.anchors.right.obj != nil:
    if obj.anchors.left.obj != nil:
      obj.w[] = obj.anchors.right.pos(isY=false).posToLocal(obj.parent).x - obj.x[]
    else:
      obj.x[] = obj.anchors.right.pos(isY=false).posToLocal(obj.parent).x - obj.w[]
  
  if obj.anchors.centerX.obj != nil:
    obj.x[] = obj.anchors.centerX.pos(isY=false).posToLocal(obj.parent).x - obj.w[] / 2

  # y and h
  if obj.anchors.top.obj != nil:
    obj.y[] = obj.anchors.top.pos(isY=true).posToLocal(obj.parent).y
  
  if obj.anchors.bottom.obj != nil:
    if obj.anchors.top.obj != nil:
      obj.h[] = obj.anchors.bottom.pos(isY=true).posToLocal(obj.parent).y - obj.y[]
    else:
      obj.y[] = obj.anchors.bottom.pos(isY=true).posToLocal(obj.parent).y - obj.h[]
  
  if obj.anchors.centerY.obj != nil:
    obj.y[] = obj.anchors.centerY.pos(isY=true).posToLocal(obj.parent).y - obj.h[] / 2


proc left*(obj: Uiobj, margin: float32 = 0): Anchor =
  Anchor(obj: obj, offsetFrom: start, offset: margin)
proc right*(obj: Uiobj, margin: float32 = 0): Anchor =
  Anchor(obj: obj, offsetFrom: `end`, offset: margin)
proc top*(obj: Uiobj, margin: float32 = 0): Anchor =
  Anchor(obj: obj, offsetFrom: start, offset: margin)
proc bottom*(obj: Uiobj, margin: float32 = 0): Anchor =
  Anchor(obj: obj, offsetFrom: `end`, offset: margin)
proc center*(obj: Uiobj, margin: float32 = 0): Anchor =
  Anchor(obj: obj, offsetFrom: center, offset: margin)

proc `+`*(a: Anchor, offset: float32): Anchor =
  Anchor(obj: a.obj, offsetFrom: a.offsetFrom, offset: a.offset + offset)

proc `-`*(a: Anchor, offset: float32): Anchor =
  Anchor(obj: a.obj, offsetFrom: a.offsetFrom, offset: a.offset - offset)

proc handleChangedEvent(this: Uiobj, anchor: var Anchor, isY: bool) =
  if isY:
    case anchor.offsetFrom:
    of start:
      anchor.obj.x.changed.connectTo anchor: this.applyAnchors()
    of `end`:
      anchor.obj.x.changed.connectTo anchor: this.applyAnchors()
      anchor.obj.w.changed.connectTo anchor: this.applyAnchors()
    of center:
      anchor.obj.x.changed.connectTo anchor: this.applyAnchors()
      anchor.obj.w.changed.connectTo anchor: this.applyAnchors()
  else:
    case anchor.offsetFrom:
    of start:
      anchor.obj.y.changed.connectTo anchor: this.applyAnchors()
    of `end`:
      anchor.obj.y.changed.connectTo anchor: this.applyAnchors()
      anchor.obj.h.changed.connectTo anchor: this.applyAnchors()
    of center:
      anchor.obj.y.changed.connectTo anchor: this.applyAnchors()
      anchor.obj.h.changed.connectTo anchor: this.applyAnchors()
  anchor.obj.visibility.changed.connectTo anchor: this.applyAnchors()

template anchorAssign(anchor: untyped, isY: bool): untyped {.dirty.} =
  proc `anchor=`*(obj: Uiobj, v: Anchor) =
    obj.anchors.anchor = v
    handleChangedEvent(obj, obj.anchors.anchor, isY)

anchorAssign left, false
anchorAssign right, false
anchorAssign top, true
anchorAssign bottom, true
anchorAssign centerX, false
anchorAssign centerY, true


method init*(obj: Uiobj) {.base.} =
  obj.visibility.changed.connectTo obj:
    obj.recieve(VisibilityChanged(sender: obj, visibility: obj.visibility))
  
  if not obj.attachedToWindow:
    let win = obj.parentUiWindow
    if win != nil:
      obj.recieve(AttachedToWindow(window: win))

  obj.initialized = true

proc initIfNeeded*(obj: Uiobj) =
  if obj.initialized: return
  obj.init

#--- Anchors ---

proc fillHorizontal*(this: Uiobj, obj: Uiobj, margin: float32 = 0) =
  this.left = obj.left + margin
  this.right = obj.right - margin

proc fillVertical*(this: Uiobj, obj: Uiobj, margin: float32 = 0) =
  this.top = obj.top + margin
  this.bottom = obj.bottom - margin

proc centerIn*(this: Uiobj, obj: Uiobj, offset: Vec2 = vec2(), xCenterAt: AnchorOffsetFrom = center, yCenterAt: AnchorOffsetFrom = center) =
  this.centerX = Anchor(obj: obj, offsetFrom: xCenterAt, offset: offset.x)
  this.centerY = Anchor(obj: obj, offsetFrom: yCenterAt, offset: offset.y)

proc fill*(this: Uiobj, obj: Uiobj, margin: float32 = 0) =
  this.fillHorizontal(obj, margin)
  this.fillVertical(obj, margin)

proc fill*(this: Uiobj, obj: Uiobj, marginX: float32, marginY: float32) =
  this.fillHorizontal(obj, marginX)
  this.fillVertical(obj, marginY)


method addChild*(parent: Uiobj, child: Uiobj) {.base.} =
  assert child.parent == nil
  child.parent = parent
  parent.childs.add child
  if not child.attachedToWindow and parent.attachedToWindow:
    let win = parent.parentUiWindow
    if win != nil:
      child.recieve(AttachedToWindow(window: win))
  child.recieve(ParentChanged(newParentInTree: parent))


method addChangableChildUntyped*(parent: Uiobj, child: Uiobj): CustomProperty[Uiobj] {.base.} =
  assert child != nil
  
  # add to parent.childs seq even if addChild is overrided
  assert child.parent == nil
  child.parent = parent
  parent.childs.add child
  if not child.attachedToWindow and parent.attachedToWindow:
    let win = parent.parentUiWindow
    if win != nil:
      child.recieve(AttachedToWindow(window: win))
  child.recieve(ParentChanged(newParentInTree: parent))

  let i = parent.childs.high
  result = CustomProperty[Uiobj](
    get: proc(): Uiobj = parent.childs[i],
    set: (proc(v: Uiobj) =
      parent.childs[i].parent = nil
      parent.childs[i] = v
      v.parent = parent
      v.recieve(ParentChanged(newParentInTree: parent))
    ),
  )


proc addChangableChild*[T: UiObj](parent: Uiobj, child: T): CustomProperty[T] =
  var prop = parent.addChangableChildUntyped(child)
  cast[ptr CustomProperty[UiObj]](result.addr)[] = move prop



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


proc passTransform(ctx: DrawContext, shader: tuple, pos = vec2(), size = vec2(10, 10), angle: float32 = 0, flipY = false) =
  shader.transform.uniform =
    translate(vec3(ctx.px*(vec2(pos.x, -pos.y) - ctx.wh - (if flipY: vec2(0, size.y) else: vec2())), 0)) *
    scale(if flipY: vec3(1, -1, 1) else: vec3(1, 1, 1)) *
    rotate(angle, vec3(0, 0, 1))
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
    ], [
      0'u32, 1, 2,
      2, 3, 0,
    ]
  )


proc updateSizeRender(ctx: DrawContext, size: IVec2) =
  # update size
  ctx.px = vec2(2'f32 / size.x.float32, 2'f32 / size.y.float32)
  ctx.wh = ivec2(size.x, -size.y).vec2 / 2


proc drawRect*(ctx: DrawContext, pos: Vec2, size: Vec2, col: Vec4, radius: float32, blend: bool, angle: float32) =
  # draw rect
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.solid.shader
  ctx.passTransform(ctx.solid, pos=pos, size=size, angle=angle)
  ctx.solid.radius.uniform = radius
  ctx.solid.color.uniform = col
  draw ctx.rect
  if blend: glDisable(GlBlend)

proc drawImage*(ctx: DrawContext, pos: Vec2, size: Vec2, tex: GlUint, radius: float32, blend: bool, angle: float32, flipY = false) =
  # draw image
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.image.shader
  ctx.passTransform(ctx.image, pos=pos, size=size, angle=angle, flipY=flipY)
  ctx.image.radius.uniform = radius
  glBindTexture(GlTexture2d, tex)
  draw ctx.rect
  glBindTexture(GlTexture2d, 0)
  if blend: glDisable(GlBlend)

proc drawIcon*(ctx: DrawContext, pos: Vec2, size: Vec2, tex: GlUint, col: Vec4, radius: float32, blend: bool, angle: float32) =
  # draw image (with solid color)
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.icon.shader
  ctx.passTransform(ctx.icon, pos=pos, size=size, angle=angle)
  ctx.icon.radius.uniform = radius
  ctx.icon.color.uniform = col
  glBindTexture(GlTexture2d, tex)
  draw ctx.rect
  glBindTexture(GlTexture2d, 0)
  if blend: glDisable(GlBlend)

proc drawShadowRect*(ctx: DrawContext, pos: Vec2, size: Vec2, col: Vec4, radius: float32, blend: bool, blurRadius: float32, angle: float32) =
  # draw rect
  if blend:
    glEnable(GlBlend)
    glBlendFuncSeparate(GlOne, GlOneMinusSrcAlpha, GlOne, GlOne)
  use ctx.rectShadow.shader
  ctx.passTransform(ctx.rectShadow, pos=pos, size=size, angle=angle)
  ctx.rectShadow.radius.uniform = radius
  ctx.rectShadow.color.uniform = col
  ctx.rectShadow.blurRadius.uniform = blurRadius
  draw ctx.rect
  if blend: glDisable(GlBlend)



#----- Basic Components -----


proc `image=`*(obj: UiImage, img: pixie.Image) =
  obj.tex = nil
  if img != nil:
    obj.tex = newTextures(1)
    loadTexture(obj.tex[0], img)
    if obj.wh[] == vec2():
      obj.wh[] = vec2(img.width.float32, img.height.float32)
    obj.imageWh[] = ivec2(img.width.int32, img.height.int32)

proc `image=`*(obj: UiImage, img: imageman.Image[ColorRGBAU]) =
  obj.tex = newTextures(1)
  loadTexture(obj.tex[0], img)
  if obj.wh[] == vec2():
    obj.wh[] = vec2(img.width.float32, img.height.float32)
  obj.imageWh[] = ivec2(img.width.int32, img.height.int32)


method draw*(rect: UiRect, ctx: DrawContext) =
  if rect.visibility[] == visible:
    ctx.drawRect(rect.xy[].posToGlobal(rect.parent), rect.wh[], rect.color.vec4, rect.radius, rect.color[].a != 1 or rect.radius != 0, rect.angle)
  procCall draw(rect.Uiobj, ctx)


method draw*(img: UiImage, ctx: DrawContext) =
  if img.visibility[] == visible and img.tex != nil:
    ctx.drawImage(img.xy[].posToGlobal(img.parent), img.wh[], img.tex[0], img.radius, img.blend or img.radius != 0, img.angle)
  procCall draw(img.Uiobj, ctx)


method draw*(ico: UiIcon, ctx: DrawContext) =
  if ico.visibility[] == visible and ico.tex != nil:
    ctx.drawIcon(ico.xy[].posToGlobal(ico.parent), ico.wh[], ico.tex[0], ico.color.vec4, ico.radius, ico.blend or ico.radius != 0, ico.angle)
  procCall draw(ico.Uiobj, ctx)


method init*(this: UiText) =
  procCall this.super.init
  
  this.arrangement.changed.connectTo this:
    this.tex = nil
    if e != nil:
      let bounds = this.arrangement[].layoutBounds
      this.wh[] = bounds
      if bounds.x == 0 or bounds.y == 0: return
      let image = newImage(bounds.x.ceil.int32, bounds.y.ceil.int32)
      image.fillText(this.arrangement[])
      this.tex = newTextures(1)
      loadTexture(this.tex[0], image)
      # todo: reposition
    else:
      this.wh[] = vec2()

  template newArrangement: Arrangement =
    if this.text[] != "" and this.font != nil:
      typeset(this.font[], this.text[], this.bounds[], this.hAlign[], this.vAlign[], this.wrap[])
    else: nil

  this.text.changed.connectTo this: this.arrangement[] = newArrangement
  this.font.changed.connectTo this: this.arrangement[] = newArrangement
  this.bounds.changed.connectTo this: this.arrangement[] = newArrangement
  this.hAlign.changed.connectTo this: this.arrangement[] = newArrangement
  this.vAlign.changed.connectTo this: this.arrangement[] = newArrangement
  this.wrap.changed.connectTo this: this.arrangement[] = newArrangement


method draw*(text: UiText, ctx: DrawContext) =
  let pos =
    if text.roundPositionOnDraw[]:
      text.xy[].posToGlobal(text.parent).round
    else:
      text.xy[].posToGlobal(text.parent)

  if text.visibility[] == visible and text.tex != nil:
    ctx.drawIcon(pos, text.wh[], text.tex[0], text.color.vec4, 0, true, text.angle)
  procCall draw(text.Uiobj, ctx)


method draw*(rect: UiRectShadow, ctx: DrawContext) =
  if rect.visibility[] == visible:
    ctx.drawShadowRect(rect.xy[].posToGlobal(rect.parent), rect.wh[], rect.color.vec4, rect.radius, true, rect.blurRadius, rect.angle)
  procCall draw(rect.Uiobj, ctx)


method draw*(rect: UiClipRect, ctx: DrawContext) =
  if rect.visibility == visible:
    if rect.w[] <= 0 or rect.h[] <= 0: return
    if rect.fbo == nil: rect.fbo = newFrameBuffers(1)

    let size = ivec2(rect.w[].round.int32, rect.h[].round.int32)

    ctx.frameBufferHierarchy.add (rect.fbo[0], size)
    glBindFramebuffer(GlFramebuffer, rect.fbo[0])
    
    if rect.prevSize != size or rect.tex == nil:
      rect.prevSize = size
      rect.tex = newTextures(1)
      glBindTexture(GlTexture2d, rect.tex[0])
      glTexImage2D(GlTexture2d, 0, GlRgba.Glint, size.x, size.y, 0, GlRgba, GlUnsignedByte, nil)
      glTexParameteri(GlTexture2d, GlTextureMinFilter, GlNearest)
      glTexParameteri(GlTexture2d, GlTextureMagFilter, GlNearest)
      glFramebufferTexture2D(GlFramebuffer, GlColorAttachment0, GlTexture2d, rect.tex[0], 0)
    else:
      glBindTexture(GlTexture2d, rect.tex[0])
    
    glClearColor(0, 0, 0, 0)
    glClear(GlColorBufferBit)
    
    glViewport 0, 0, size.x.GLsizei, size.y.GLsizei
    ctx.updateSizeRender(size)

    let gt = rect.globalTransform[]
    let pos = rect.xy[]
    try:
      rect.globalTransform{} = true
      rect.xy[] = vec2()
      procCall draw(rect.Uiobj, ctx)
    
    finally:
      ctx.frameBufferHierarchy.del ctx.frameBufferHierarchy.high
      rect.globalTransform{} = gt
      rect.xy[] = pos

      glBindFramebuffer(GlFramebuffer, if ctx.frameBufferHierarchy.len == 0: 0.GlUint else: ctx.frameBufferHierarchy[^1].fbo)
      
      let size = if ctx.frameBufferHierarchy.len == 0: rect.parentWindow.size else: ctx.frameBufferHierarchy[^1].size
      glViewport 0, 0, size.x.GLsizei, size.y.GLsizei
      ctx.updateSizeRender(size)
      
      ctx.drawImage(rect.xy[].posToGlobal(rect.parent), rect.wh[], rect.tex[0], rect.radius, true, rect.angle, flipY=true)
  else:
    procCall draw(rect.Uiobj, ctx)


method draw*(win: UiWindow, ctx: DrawContext) =
  glClearColor(win.clearColor.r, win.clearColor.g, win.clearColor.b, win.clearColor.a)
  glClear(GlColorBufferBit or GlDepthBufferBit)
  procCall draw(win.Uiobj, ctx)


method recieve*(this: UiWindow, signal: Signal) =
  if signal of WindowEvent and signal.WindowEvent.event of ResizeEvent:
    let e = (ref ResizeEvent)signal.WindowEvent.event
    this.wh[] = e.size.vec2
    glViewport 0, 0, e.size.x.GLsizei, e.size.y.GLsizei
    this.ctx.updateSizeRender(e.size)

  elif signal of WindowEvent and signal.WindowEvent.event of RenderEvent:
    draw(this, this.ctx)

  elif signal of WindowEvent and signal.WindowEvent.event of FocusChangedEvent:
    redraw this.siwinWindow

  procCall this.super.recieve(signal)


proc setupEventsHandling*(win: UiWindow) =
  proc toRef[T](e: T): ref AnyWindowEvent =
    result = (ref T)()
    (ref T)(result)[] = e

  win.siwinWindow.eventsHandler = WindowEventsHandler(
    onClose:       proc(e: CloseEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onRender:      proc(e: RenderEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onTick:        proc(e: TickEvent) = win.onTick.emit(e),
    onResize:      proc(e: ResizeEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onWindowMove:  proc(e: WindowMoveEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),

    onFocusChanged:       proc(e: FocusChangedEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onFullscreenChanged:  proc(e: FullscreenChangedEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onMaximizedChanged:   proc(e: MaximizedChangedEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),

    onMouseMove:    proc(e: MouseMoveEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onMouseButton:  proc(e: MouseButtonEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onScroll:       proc(e: ScrollEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onClick:        proc(e: ClickEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),

    onKey:   proc(e: KeyEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
    onTextInput:  proc(e: TextInputEvent) = win.recieve(WindowEvent(sender: win, event: e.toRef)),
  )

proc newUiWindow*(siwinWindow: Window): UiWindow =
  result = UiWindow(siwinWindow: siwinWindow)
  loadExtensions()
  result.setupEventsHandling
  result.ctx = newDrawContext()


method addChild*(this: UiWindow, child: Uiobj) =
  procCall this.super.addChild(child)
  child.recieve(AttachedToWindow(window: this))
        


proc newUiobj*(): Uiobj = new result
proc newUiWindow*(): UiWindow = new result
proc newUiImage*(): UiImage = new result
proc newUiIcon*(): UiIcon = new result
proc newUiText*(): UiText = new result
proc newUiRect*(): UiRect = new result
proc newUiClipRect*(): UiClipRect = new result
proc newUiRectShadow*(): UiRectShadow = new result


#----- Macros -----



macro makeLayout*(obj: Uiobj, body: untyped) =
  ## tip: use a.makeLauyout(-soMeFuN()) instead of (let b = soMeFuN(); a.addChild(b); init b)
  runnableExamples:
    let a = UiRect()
    let b = UiRect()
    let c = UiRect()
    a.makeLayout:
      - UiRectShadow(radius: 7.5, blurRadius: 10, color: color(0, 0, 0, 0.3)) as shadowEfect

      - newUiRect():
        this.anchors.fill(parent)
        echo shadowEffect.radius
        doassert parent == this.parent

        - UiClipRect(radius: 7.5):
          this.anchors.fill(parent, 10)
          doassert root == this.parent.parent

          ooo --- UiRect():  # add changable child
            this.anchors.fill(parent)
          #[ equivalent to (roughly):
          ooo = block:
            let x = this.addChangableChild(UiRect())
            proc update(parent: typeof(this), this: typeof(x[])) =
              initIfNeeded(this)
              this.anchors.fill(parent)
            update(this, x[])
            x.changed.connectTo this: update(this, x[])
            x
          ]#

          - b
          - UiRect()

      - c:
        this.anchors.fill(parent)


  proc implFwd(body: NimNode, res: var seq[NimNode]) =
    for x in body:
      case x
      of Prefix[Ident(strVal: "-"), @ctor]:
        discard

      of Prefix[Ident(strVal: "-"), @ctor, @body is StmtList()]:
        implFwd(body, res)

      of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s]:
        res.add: buildAst:
          identDefs(s, empty(), ctor)

      of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s, @body is StmtList()]:
        res.add: buildAst:
          identDefs(s, empty(), ctor)
        implFwd(body, res)

      else: discard

  proc impl(parent: NimNode, obj: NimNode, body: NimNode): NimNode =
    buildAst blockStmt:
      genSym(nskLabel, "initializationBlock")
      call:
        lambda:
          empty(); empty(); empty()
          formalParams:
            empty()
            identDefs(ident "parent", call(bindSym"typeof", parent), empty())
            identDefs(ident "this", call(bindSym"typeof", obj), empty())
          empty(); empty()
          
          stmtList:
            call(ident"initIfNeeded", ident "this")
            
            proc checkCtor(ctor: NimNode): bool =
              if ctor == ident "root": warning("adding root to itself causes recursion", ctor)
              if ctor == ident "this": warning("adding this to itself causes recursion", ctor)
              if ctor == ident "parent": warning("adding parent to itself causes recursion", ctor)

            proc changableImpl(ctor, body: NimNode): NimNode =
              buildAst:
                blockStmt:
                  genSym(nskLabel, "changableChildInitializationBlock")
                  stmtList:
                    discard checkCtor ctor
                    let
                      prop = genSym(nskVar)
                      updateProc = genSym(nskProc)
                    
                    varSection:
                      identDefs(prop, empty(), call(bindSym"addChangableChild", ident "this", ctor))
                    
                    procDef:
                      updateProc
                      empty(); empty()
                      formalParams:
                        empty()
                        identDefs(ident"parent", call(bindSym"typeof", ident"this"), empty())
                        identDefs(ident"this", call(bindSym"typeof", bracketExpr(prop)), empty())
                      empty(); empty()
                      stmtList:
                        if body == nil:
                          call ident"initIfNeeded":
                            ident "this"
                        if body != nil: impl(ident"parent", ident"this", body)

                    call updateProc:
                      ident "this"
                      bracketExpr(prop)
                    
                    call bindSym"connectTo":
                      dotExpr(prop, ident"changed")
                      ident "this"
                      stmtList:
                        call updateProc:
                          ident "this"
                          bracketExpr(prop)
                    
                    call bindSym"move":
                      prop


            for x in body:
              case x
              of Prefix[Ident(strVal: "-"), @ctor]:
                discard checkCtor ctor
                let s = genSym(nskLet)
                letSection:
                  identDefs(s, empty(), ctor)
                call(ident"addChild", ident "this", s)
                call(ident"initIfNeeded", s)

              of Prefix[Ident(strVal: "-"), @ctor, @body is StmtList()]:
                discard checkCtor ctor
                let s = genSym(nskLet)
                letSection:
                  identDefs(s, empty(), ctor)
                call(ident"addChild", ident "this", s)
                impl(ident "this", s, body)

              of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s]:
                discard checkCtor ctor
                call(ident"addChild", ident "this", s)
                call(ident"initIfNeeded", s)

              of Infix[Ident(strVal: "as"), Prefix[Ident(strVal: "-"), @ctor], @s, @body is StmtList()]:
                discard checkCtor ctor
                call(ident"addChild", ident "this", s)
                impl(ident "this", s, body)

              of Infix[Ident(strVal: "---"), @to, @ctor]:
                asgn:
                  to
                  changableImpl(ctor, nil)

              of Infix[Ident(strVal: "---"), @to, @ctor, @body is StmtList()]:
                asgn:
                  to
                  changableImpl(ctor, body)
              
              of ForStmt[@v, @cond, @body]:
                forStmt:
                  v
                  cond
                  stmtList:
                    letSection:
                      var fwd: seq[NimNode]
                      (implFwd(body, fwd))
                      for x in fwd: x
                    impl(ident "parent", ident "this", body)

              else: x
        parent
        obj

  buildAst blockStmt:
    genSym(nskLabel, "makeLayoutBlock")
    stmtList:
      letSection:
        identDefs(pragmaExpr(ident "root", pragma ident "used"), empty(), obj)
        var fwd: seq[NimNode]
        (implFwd(body, fwd))
        for x in fwd: x
      
      impl(nnkDotExpr.newTree(ident "root", ident "parent"), ident "root", if body.kind == nnkStmtList: body else: newStmtList(body))


proc bindingImpl*(obj: NimNode, target: NimNode, body: NimNode, afterUpdate: NimNode, redraw: bool, init: bool, kind: BindingKind): NimNode =
  ## connects update proc to every x[] property changed, and invokes update proc instantly
  runnableExamples:
    type MyObj = ref object of Uiobj
      c: Property[int]

    obj.binding c:
      if config.csd[]: parent[].b else: 10[]

    # convers to (roughly):
    block bindingBlock:
      let o {.cursor.} = obj
      proc updateC(this: MyObj) =
        this.c[] = if config.csd[]: parent[].b else: 10[]

      config.csd.changed.connectTo o: updateC(this)
      parent.changed.connectTo o: updateC(this)
      10.changed.connectTo o: updateC(this)  # yes, 10[] will considered property too
      updateC(o)
  
  let updateProc = genSym(nskProc)
  let objCursor = genSym(nskLet)
  let thisInProc = genSym(nskParam)
  var alreadyBinded: seq[NimNode]

  proc impl(stmts: var seq[NimNode], obj, body: NimNode) =
    case body
    of in alreadyBinded: return
    of Call[Sym(strVal: "[]"), @exp]:
      stmts.add: buildAst(call):
        ident "connectTo"
        dotExpr(exp, ident "changed")
        objCursor
        call updateProc:
          objCursor
      alreadyBinded.add body
      impl(stmts, obj, exp)

    else:
      for x in body: impl(stmts, obj, x)
  
  result = buildAst(blockStmt):
    ident "bindingBlock"
    stmtList:
      letSection:
        identDefs(objCursor, empty(), obj)
      
      procDef updateProc:
        empty(); empty()
        formalParams:
          empty()
          identDefs(thisInProc, obj.getType, empty())
        empty(); empty()
        stmtList:
          case kind
          of bindProperty:
            asgn:
              bracketExpr dotExpr(thisInProc, target)
              body
          of bindValue:
            asgn:
              target
              body
          of bindProc:
            call:
              target
              thisInProc
              body
          
          case afterUpdate
          of Call[Sym(strVal: "newStmtList"), HiddenStdConv[Empty(), Bracket()]]: discard
          else: afterUpdate
          
          if redraw: call bindSym "redraw", thisInProc
      
      var stmts: seq[NimNode]
      (impl(stmts, obj, body))
      for x in stmts: x
      if init:
        call updateProc, objCursor


macro binding*(obj: EventHandler, target: untyped, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindProperty)

macro bindingValue*(obj: EventHandler, target: typed, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindValue)

macro bindingProc*(obj: EventHandler, target: typed, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindProc)


macro binding*[T: HasEventHandler](obj: T, target: untyped, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindProperty)

macro bindingValue*[T: HasEventHandler](obj: T, target: typed, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindValue)

macro bindingProc*[T: HasEventHandler](obj: T, target: typed, body: typed, afterUpdate: typed = newStmtList(), redraw: static bool = true, init: static bool = true): untyped =
  bindingImpl(obj, target, body, afterUpdate, redraw, init, bindProc)


template buildIt*[T](obj: T, body: untyped): T =
  ## for situations like:
  ##   this.font[] = newFont(typeface).buildIt:
  ##     it.size = 14
  ## 
  ## use buildIt instead of:
  ##   this.font[] = block:
  ##     let font = newFont(typeface)
  ##     font.size = 14
  ##     font
  block:
    var it {.inject.} = obj
    body
    it


template withWindow*(obj: UiObj, winVar: untyped, body: untyped) =
  proc bodyProc(winVar {.inject.}: UiWindow) =
    body
  if obj.attachedToWindow:
    bodyProc(obj.parentUiWindow)
  obj.onSignal.connect obj.eventHandler, proc(e: Signal) =
    if e of AttachedToWindow:
      bodyProc(obj.parentUiWindow)


proc preview*(size = ivec2(), clearColor = color(0, 0, 0, 0), margin = 10'f32, transparent = false, withWindow: proc(): Uiobj) =
  let win = newOpenglWindow(
    size =
      if size != ivec2(): size
      else: ivec2(100, 100),
    transparent = transparent
  ).newUiWindow
  let obj = withWindow()

  if size == ivec2() and obj.wh[] != vec2():
    win.siwinWindow.size = (obj.wh[] + margin * 2).ivec2

  win.clearColor = clearColor
  win.makeLayout:
    - obj:
      this.fill(parent, margin)
  
  run win.siwinWindow
