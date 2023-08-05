import siwin
import uibase

type
  GlobalShortcut* = ref object of Uiobj
    sequence*: set[Key]
    action*: proc()


proc globalShortcut*(sequence: set[Key]): GlobalShortcut =
  result = GlobalShortcut(sequence: sequence)

method recieve*(this: GlobalShortcut, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea of KeyEvent(), handled: false):
    let e = (ref KeyEvent)ea
    if e.pressed and e.window.keyboard.pressed == this.sequence:
      this.action()
  
  procCall this.super.recieve(signal)
