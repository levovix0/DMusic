import options
import siwin
import ../configuration
import ./[uibase, style, mouseArea]

type
  Button = ref object of UiRect
    action: proc()
    icon: UiIcon
    style: Property[Style]
    accent: Property[bool]

  WindowHeader* = ref object of UiRect
    style: Property[Style]


method recieve(this: Button, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style[] = style
  
  procCall this.super.recieve(signal)


proc newButton*(icon: string): Button =
  result = Button()
  result.makeLayout:
    this.wh[] = vec2(50, 40)

    - newUiMouseArea() as mouse:
      this.fill parent

      this.mouseDownAndUpInside.connectTo root:
        root.action()

    - UiIcon() as ico:
      this.image = icon.decodeImage
      this.centerIn parent
      root.icon = ico

      this.binding color:
        if parent.style[] != nil:
          if mouse.pressed[]:
            if parent.accent[]: parent.style[].accentButton.pressedColor
            else: parent.style[].button.pressedColor
          elif mouse.hovered[]:
            if parent.accent[]: parent.style[].accentButton.hoverColor
            else: parent.style[].button.hoverColor
          else:
            if parent.accent[]: parent.style[].accentButton.color
            else: parent.style[].button.color
        else: color(0, 0, 0)
    
    this.binding color:
      if this.style[] != nil:
        if mouse.pressed[]:
          if this.accent[]: this.style[].accentButton.pressedBackgroundColor
          else: this.style[].button.pressedBackgroundColor
        elif mouse.hovered[]:
          if this.accent[]: this.style[].accentButton.hoverBackgroundColor
          else: this.style[].button.hoverBackgroundColor
        else:
          if this.accent[]: this.style[].accentButton.backgroundColor
          else: this.style[].button.backgroundColor
      else: color(0, 0, 0)


method recieve*(this: WindowHeader, signal: Signal) =
  case signal
  
  of of StyleChanged(fullStyle: @style):
    this.style[] = style.header
    signal.StyleChanged.withStyleForChilds header:
      procCall this.super.recieve(signal)

  else:
    procCall this.super.recieve(signal)


proc newWindowHeader*(): WindowHeader =
  result = WindowHeader()
  result.makeLayout:
    this.binding color: (if this.style[] != nil: this.style[].backgroundColor else: color(0, 0, 0))

    - newUiMouseArea():
      this.fill parent

      this.dragged.connectTo root:
        root.parentWindow.startInteractiveMove(some e)
      
      this.clicked.connectTo root:
        if e.double:
          e.window.maximized = not e.window.maximized

      - newButton(static(staticRead "../../../resources/title/close.svg")) as close:
        this.anchors.right = parent.right
        this.accent[] = true
        this.action = proc =
          close this.parentWindow
        
        this.binding visibility: (if config.csd[] and config.window_closeButton[]: Visibility.visible else: Visibility.collapsed)
      
      - newButton(static(staticRead "../../../resources/title/maximize.svg")) as maximize:
        this.anchors.right = close.left
        this.action = proc =
          let win = this.parentWindow
          win.maximized = not win.maximized
        
        this.binding visibility: (if config.csd[] and config.window_maximizeButton[]: Visibility.visible else: Visibility.collapsed)
      
      - newButton(static(staticRead "../../../resources/title/minimize.svg")) as minimize:
        this.anchors.right = maximize.left
        this.action = proc =
          this.parentWindow.minimized = true
        
        this.binding visibility: (if config.csd[] and config.window_minimizeButton[]: Visibility.visible else: Visibility.collapsed)

