import siwin
import ../configuration
import uibase, style

type
  Button = ref object of UiRect
    action: proc()
    icon: UiIcon
    style: Property[Style]
    pressed: Property[bool]
    accent: Property[bool]

  WindowHeader* = ref object of UiRect
    style: Property[Style]


method init(this: Button) =
  procCall this.super.init
  this.hovered.changed.connectTo this:
    this.pressed[] = false


method recieve(this: Button, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style[] = style
  
  procCall this.super.recieve(signal)
  if this.visibility == collapsed: return

  case signal
  of of WindowEvent(event: @ea is of MouseButtonEvent(), handled: false):
    let e = (ref MouseButtonEvent)ea
    if this.hovered:
      if not e.generated:
        if e.pressed and e.button == MouseButton.left:
          this.pressed[] = true
          signal.WindowEvent.handled = true
        elif not e.pressed and e.button == MouseButton.left and this.pressed:
          this.action()
          this.pressed[] = false
          signal.WindowEvent.handled = true
      else:
        this.pressed[] = false


proc newButton*(icon: string): Button =
  result = Button()
  result.makeLayout:
    this.box.wh = vec2(50, 40)

    - UiIcon() as ico:
      this.image = icon.decodeImage
      this.anchors.centerIn parent
      root.icon = ico

      this.binding color:
        if parent.style[] != nil:
          if parent.pressed[]:
            if parent.accent[]: parent.style[].accentButton.pressedColor
            else: parent.style[].button.pressedColor
          elif parent.hovered[]:
            if parent.accent[]: parent.style[].accentButton.hoverColor
            else: parent.style[].button.hoverColor
          else:
            if parent.accent[]: parent.style[].accentButton.color
            else: parent.style[].button.color
        else: color(0, 0, 0)
    
    this.binding color:
      if this.style[] != nil:
        if this.pressed[]:
          if this.accent[]: this.style[].accentButton.pressedBackgroundColor
          else: this.style[].button.pressedBackgroundColor
        elif this.hovered[]:
          if this.accent[]: this.style[].accentButton.hoverBackgroundColor
          else: this.style[].button.hoverBackgroundColor
        else:
          if this.accent[]: this.style[].accentButton.backgroundColor
          else: this.style[].button.backgroundColor
      else: color(0, 0, 0)


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
    this.style[] = style.header
    signal.StyleChanged.withStyleForChilds header:
      procCall this.super.recieve(signal)

  else:
    procCall this.super.recieve(signal)
  
  case signal
  of of WindowEvent(event: @ea of ClickEvent(), handled: false):
    let e = (ref ClickEvent)ea
    if this.hovered[] and e.double:
      e.window.maximized = not e.window.maximized
      signal.WindowEvent.handled = true


proc newWindowHeader*(): WindowHeader =
  result = WindowHeader()
  result.makeLayout:
    this.binding color: (if this.style[] != nil: this.style[].backgroundColor else: color(0, 0, 0))

    - newButton(static(staticRead "../../../resources/title/close.svg")) as close:
      this.anchors.right = parent.right
      this.accent[] = true
      this.action = proc =
        close this.parentWindow
      
      this.binding visibility: (if config.csd[] and config.window_closeButton[]: Visibility.visible else: Visibility.collapsed)
      do: startReposition root
    
    - newButton(static(staticRead "../../../resources/title/maximize.svg")) as maximize:
      this.anchors.right = close.left
      this.action = proc =
        let win = this.parentWindow
        win.maximized = not win.maximized
      
      this.binding visibility: (if config.csd[] and config.window_maximizeButton[]: Visibility.visible else: Visibility.collapsed)
      do: startReposition root
    
    - newButton(static(staticRead "../../../resources/title/minimize.svg")) as minimize:
      this.anchors.right = maximize.left
      this.action = proc =
        this.parentWindow.minimized = true
      
      this.binding visibility: (if config.csd[] and config.window_minimizeButton[]: Visibility.visible else: Visibility.collapsed)
      do: startReposition root

