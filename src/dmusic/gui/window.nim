import siwin
import ../configuration
import ./[uibase, style, mouseArea]

type
  DmusicWindow* = ref object of Uiobj
    edge: int  # 8 edges (1..8), from top to top-left 
    borderWidth: float32
    style: Property[Style]
    windowFrame {.cursor.}: UiRect
    clipRect {.cursor.}: UiClipRect
    wasChangedCursor: bool
    mouse: UiMouseArea


proc updateChilds(this: DmusicWindow, initial = false) =
  if this.parentWindow.maximized:
    this.borderWidth = -1
    this.clipRect.visibility[] = hidden
    this.clipRect.anchors.fill(this, 0)
  else:
    this.borderWidth = if config.csd: 10 else: -1
    this.clipRect.visibility[] = if config.csd: Visibility.visible else: Visibility.hidden
    this.clipRect.anchors.fill(this, if config.csd: 10 else: 0)
  if not initial:
    this.parentUiWindow.startReposition()
    redraw this


method recieve*(this: DmusicWindow, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent(), handled: false):
    let e = (ref MouseMoveEvent)ea
    if this.mouse.hovered and MouseButton.left in e.window.mouse.pressed:
      if this.edge != 0:
        e.window.startInteractiveResize(
          case this.edge
          of 1: Edge.top
          of 2: Edge.topRight
          of 3: Edge.right
          of 4: Edge.bottomRight
          of 5: Edge.bottom
          of 6: Edge.bottomLeft
          of 7: Edge.left
          of 8: Edge.topLeft
          else: Edge.left
        )
        signal.WindowEvent.handled = true
      else:
        procCall this.super.recieve(signal)
    else:
      let pos = e.pos.vec2.posToLocal(this)
      let box = this.box

      let left = pos.x in 0'f32..(box.x + this.borderWidth)
      let top = pos.y in 0'f32..(box.y + this.borderWidth)
      let right = pos.x in (box.w - this.borderWidth)..(box.w)
      let bottom = pos.y in (box.h - this.borderWidth)..(box.h)

      if left and top:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeTopLeft)
        this.edge = 8
        this.wasChangedCursor = true
      elif right and top:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeTopRight)
        this.edge = 2
        this.wasChangedCursor = true
      elif right and bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomRight)
        this.edge = 4
        this.wasChangedCursor = true
      elif left and bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomLeft)
        this.edge = 6
        this.wasChangedCursor = true
      elif left:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
        this.edge = 7
        this.wasChangedCursor = true
      elif top:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)
        this.edge = 1
        this.wasChangedCursor = true
      elif right:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
        this.edge = 3
        this.wasChangedCursor = true
      elif bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)
        this.edge = 5
        this.wasChangedCursor = true
      elif this.wasChangedCursor:
        e.window.cursor = Cursor(kind: builtin, builtin: arrow)
        this.edge = 0
        this.wasChangedCursor = false
      procCall this.super.recieve(signal)

  of of WindowEvent(event: @ea is of MaximizedChangedEvent()):
    let e = (ref MaximizedChangedEvent)ea
    updateChilds(this)
    config.window_maximized[] = e.maximized
  
  of of WindowEvent(event: @ea is of ResizeEvent()):
    let e = (ref ResizeEvent)ea
    config.window_width[] = e.size.x
    config.window_height[] = e.size.y
  
  of of StyleChanged(style: @style):
    this.style[] = style
    procCall this.super.recieve(signal)

  else:
    procCall this.super.recieve(signal)


proc createWindow*(rootObj: Uiobj): UiWindow =
  result = newOpenglWindow(
    title = "DMusic",
    size = ivec2(config.window_width[].int32, config.window_height[].int32),
    transparent = true,
    frameless = config.csd,
  ).newUiWindow
  result.siwinWindow.minSize = ivec2(540, 320)
  if config.window_maximized: result.siwinWindow.maximized = true

  let this = result
  config.csd.changed.connectTo result:
    this.siwinWindow.frameless = config.csd
  
  let dmWin = DmusicWindow()

  result.makeLayout:
    - UiRectShadow():
      this.anchors.fill(parent)
      this.radius[] = 7.5
      this.blurRadius[] = 10
      this.color[] = color(0, 0, 0, 0.3)
      this.binding visibility:
        if config.window_maximized[]: Visibility.hidden
        else:
          if config.csd[]: Visibility.visible
          else: Visibility.hidden

    - dmWin:
      this.anchors.fill(parent)

      - newUiMouseArea():
        this.anchors.fill(parent)
        dmWin.mouse = this

        - UiClipRect():
          dmWin.clipRect = this
          this.radius[] = 7.5

          - UiRect():
            this.anchors.fill(parent)
            dmWin.windowFrame = this
            this.binding color: (if dmWin.style[] != nil: dmWin.style[].backgroundColor else: color(0, 0, 0))
            
            - rootObj:
              this.anchors.fill(parent)
  

  config.csd.changed.connectTo dmWin:
    updateChilds(dmWin)
  updateChilds(dmWin, initial=true)
