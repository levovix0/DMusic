import siwin, fusion/matching
import uibase

type
  WindowHeader* = ref object of UiRect


method recieve*(this: WindowHeader, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent()):
    let e = (ref MouseMoveEvent)ea
    if MouseButton.left in e.window.mouse.pressed:
      signal.WindowEvent.handled = true
      e.window.startInteractiveMove()

  else:
    procCall this.UiRect.recieve(signal)
  
  case signal
  of of WindowEvent(event: @ea of ClickEvent(), handled: false):
    let e = (ref ClickEvent)ea
    if e.double:
      e.window.maximized = not e.window.maximized
      signal.WindowEvent.handled = true


proc newWindowHeader*(): WindowHeader =
  result = WindowHeader(color: vec4(1, 1, 1, 1))
