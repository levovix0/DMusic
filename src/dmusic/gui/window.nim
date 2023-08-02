import siwin, fusion/matching
import uibase

type
  DmusicWindow* = ref object of UiRect
    edge: int  # 8 edges (1..8), from top to top-left 
    borderWidth: float32


method recieve*(this: DmusicWindow, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent()):
    let e = (ref MouseMoveEvent)ea
    if MouseButton.left in e.window.mouse.pressed:
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
        procCall this.UiRect.recieve(signal)
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
      elif right and top:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeTopRight)
        this.edge = 2
      elif right and bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomRight)
        this.edge = 4
      elif left and bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeBottomLeft)
        this.edge = 6
      elif left:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
        this.edge = 7
      elif top:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)
        this.edge = 1
      elif right:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeHorisontal)
        this.edge = 3
      elif bottom:
        e.window.cursor = Cursor(kind: builtin, builtin: sizeVertical)
        this.edge = 5
      else:
        e.window.cursor = Cursor(kind: builtin, builtin: arrow)
        this.edge = 0
        procCall this.Uiobj.recieve(signal)

  else:
    procCall this.UiRect.recieve(signal)


proc createWindow*(root: Uiobj): UiWindow =
  result = newOpenglWindow(title="DMusic2", transparent=true, frameless=true).newUiWindow
  result.siwinWindow.minSize = ivec2(60, 60)

  let win = DmusicWindow(borderWidth: 10, color: vec4(32/255, 32/255, 32/255, 1), radius: 7.5)
  result.addChild win
  win.anchors.fill(result)

  # todo: shadow

  win.addChild root
  root.anchors.fill(win, 10)
