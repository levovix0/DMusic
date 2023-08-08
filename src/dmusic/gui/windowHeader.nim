import siwin
import ../configuration
import uibase, style

type
  Button = ref object of UiRect
    action: proc()
    icon: UiIcon
    style: Style
    pressed: bool
    accent: bool

  WindowHeader* = ref object of UiRect
    style: Style


proc updateColor(this: Button) =
  this.color[] =
    if this.pressed:
      if this.accent: this.style.accentPressedButtonBackgroundColor
      else: this.style.pressedButtonBackgroundColor
    elif this.hovered:
      if this.accent: this.style.accentHoverButtonBackgroundColor
      else: this.style.hoverButtonBackgroundColor
    else:
      if this.accent: this.style.accentButtonBackgroundColor
      else: this.style.buttonBackgroundColor
  this.icon.color[] = this.style.color
  redraw this.parentWindow


method init(this: Button) =
  this.hovered.changed.connectTo this:
    this.updateColor()
    this.pressed = false


method recieve(this: Button, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style = style
    this.updateColor()
  
  procCall this.super.recieve(signal)
  if this.visibility == collapsed: return

  case signal
  of of WindowEvent(event: @ea is of MouseButtonEvent(), handled: false):
    let e = (ref MouseButtonEvent)ea
    if this.hovered:
      if not e.generated:
        if e.pressed and e.button == MouseButton.left:
          this.pressed = true
          signal.WindowEvent.handled = true
          this.updateColor()
        elif not e.pressed and e.button == MouseButton.left and this.pressed:
          this.action()
          this.pressed = false
          signal.WindowEvent.handled = true
          this.updateColor()
      else:
        this.pressed = false
        this.updateColor()


proc newButton*(icon: string): Button =
  result = Button()
  result.makeLayout:
    this.box.wh = vec2(50, 40)
    - UiIcon() as ico:
      this.image = icon.decodeImage
      this.anchors.centerIn parent
      root.icon = ico



proc updateColor(this: WindowHeader) =
  this.color[] = this.style.backgroundColor

method recieve*(this: WindowHeader, signal: Signal) =
  case signal
  of of WindowEvent(event: @ea is of MouseMoveEvent(), fake: false):
    let e = (ref MouseMoveEvent)ea
    if this.hovered and MouseButton.left in e.window.mouse.pressed and config.csd:
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
      this.anchors.right = parent.right
      this.accent = true
      this.action = proc =
        close this.parentWindow
      
      proc update(this: typeof(this)) =
        this.visibility[] = if config.csd and config.window_closeButton: Visibility.visible else: Visibility.collapsed
        startReposition root
      this.update
      notifyWindow_closeButtonChanged.connectTo this: this.update
      notifyCsdChanged.connectTo this: this.update
    
    - newButton(static(staticRead "../../../resources/title/maximize.svg")) as maximize:
      this.anchors.right = close.left
      this.action = proc =
        let win = this.parentWindow
        win.maximized = not win.maximized
      
      proc update(this: typeof(this)) =
        this.visibility[] = if config.csd and config.window_maximizeButton: Visibility.visible else: Visibility.collapsed
        startReposition root
      this.update
      notifyWindow_maximizeButtonChanged.connectTo this: this.update
      notifyCsdChanged.connectTo this: this.update
    
    - newButton(static(staticRead "../../../resources/title/minimize.svg")) as minimize:
      this.anchors.right = maximize.left
      this.action = proc =
        this.parentWindow.minimized = true
      
      proc update(this: typeof(this)) =
        this.visibility[] = if config.csd and config.window_minimizeButton: Visibility.visible else: Visibility.collapsed
        startReposition root
      this.update
      notifyWindow_minimizeButtonChanged.connectTo this: this.update
      notifyCsdChanged.connectTo this: this.update

