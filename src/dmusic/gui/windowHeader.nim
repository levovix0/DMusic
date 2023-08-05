import siwin
import uibase, style

type
  Button = ref object of UiRect
    action: proc()
    icon: UiIcon
    style: Style = Style()

  WindowHeader* = ref object of UiRect
    style: Style = Style()


proc updateColor(this: Button) =
  this.color =
    if this.hovered: this.style.hoverButtonBackgroundColor
    else: this.style.buttonBackgroundColor
  this.icon.color = this.style.color

method recieve(this: Button, signal: Signal) =
  case signal
  of of HoveredChanged():
    this.updateColor()
    redraw this.parentWindow
  of of StyleChanged(style: @style):
    this.style = style
    this.updateColor()
    redraw this.parentWindow
  of of WindowEvent(event: @ea of ClickEvent(), handled: false):
    this.action()
  procCall this.super.recieve(signal)


proc newButton*(icon: string): Button =
  result = Button()
  result.makeLayout:
    this.box.wh = vec2(50, 40)
    - UiIcon() as ico:
      this.image = icon.decodeImage
      this.anchors.centerIn parent
      root.icon = ico



proc updateColor(this: WindowHeader) =
  this.color = this.style.backgroundColor

method recieve*(this: WindowHeader, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent()):
    let e = (ref MouseMoveEvent)ea
    if MouseButton.left in e.window.mouse.pressed:
      signal.WindowEvent.handled = true
      e.window.startInteractiveMove()
    
    else:
      procCall this.super.recieve(signal)
  
  of of StyleChanged(fullStyle: @style):
    this.style = style.header
    this.updateColor()
    signal.StyleChanged.withStyleForChilds header:
      procCall this.super.recieve(signal)

  else:
    procCall this.super.recieve(signal)
  
  case signal
  of of WindowEvent(event: @ea of ClickEvent(), handled: false):
    let e = (ref ClickEvent)ea
    if e.double:
      e.window.maximized = not e.window.maximized
      signal.WindowEvent.handled = true


proc newWindowHeader*(): WindowHeader =
  result = WindowHeader()
  result.makeLayout:
    - newButton(static(staticRead "../../../resources/title/close.svg")) as close:
      this.updateColor()
      this.anchors.right = parent.right
      this.action = proc =
        close this.parentWindow
    - newButton(static(staticRead "../../../resources/title/maximize.svg")) as maximize:
      this.updateColor()
      this.anchors.right = close.left
      this.action = proc =
        let win = this.parentWindow
        win.maximized = not win.maximized
    - newButton(static(staticRead "../../../resources/title/minimize.svg")) as minimize:
      this.updateColor()
      this.anchors.right = maximize.left
      this.action = proc =
        this.parentWindow.minimized = true

