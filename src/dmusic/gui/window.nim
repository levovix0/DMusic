import siwin
import uibase, style

type
  DmusicWindow* = ref object of Uiobj
    edge: int  # 8 edges (1..8), from top to top-left 
    borderWidth: float32
    style: Style = Style()
    windowFrame {.cursor.}: UiRect
    shadowEfect {.cursor.}: UiRectShadow
    clipRect {.cursor.}: UiClipRect
    wasChangedCursor: bool


proc updateStyle*(this: DmusicWindow) =
  this.windowFrame.color = this.style.backgroundColor

method recieve*(this: DmusicWindow, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent()):
    let e = (ref MouseMoveEvent)ea
    if this.hovered and MouseButton.left in e.window.mouse.pressed:
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
    if e.maximized:
      this.borderWidth = 0
      this.clipRect.visibility = hidden
      this.clipRect.anchors.fill(this, 0)
      this.shadowEfect.visibility = hidden
    else:
      this.borderWidth = 10
      this.clipRect.visibility = visible
      this.clipRect.anchors.fill(this, 10)
      this.shadowEfect.visibility = visible
    reposition this.parent
  
  of of StyleChanged(style: @style):
    this.style = style
    this.updateStyle()
    procCall this.super.recieve(signal)

  else:
    procCall this.super.recieve(signal)


proc createWindow*(rootObj: Uiobj): UiWindow =
  result = newOpenglWindow(title="DMusic", transparent=true, frameless=true).newUiWindow
  result.siwinWindow.minSize = ivec2(60, 60)

  result.makeLayout:
    - UiRectShadow(radius: 7.5, blurRadius: 10, color: color(0, 0, 0, 0.3)) as shadowEfect:
      this.anchors.fill(parent)

    - DmusicWindow(borderWidth: 10) as dmWin:
      this.anchors.fill(parent)
      this.shadowEfect = shadowEfect

      - UiClipRect(radius: 7.5):
        this.anchors.fill(parent, 10)
        dmWin.clipRect = this

        - UiRect():
          this.anchors.fill(parent)
          dmWin.windowFrame = this
          
          - rootObj:
            this.anchors.fill(parent)
