import siwin
import ../configuration
import uibase, style

type
  Player* = ref object of Uiobj
    style*: Property[Style]


method recieve*(this: Player, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style[] = style
  procCall this.super.recieve(signal)


proc newPlayer*(): Player =
  result = Player()
  result.makeLayout:
    - UiRect():
      this.anchors.fill(parent)
      this.binding color: (if parent.style[] != nil: parent.style[].backgroundColor else: color(0, 0, 0))
    
    - UiRect():
      this.anchors.fillHorizontal(parent)
      this.anchors.top = Anchor(obj: result, offsetFrom: start, offset: 0)
      this.box.h = 2
      this.binding color: (if parent.style[] != nil: parent.style[].borderColor else: color(0, 0, 0))
      this.binding visibility: (if parent.style[] != nil and parent.style[].borders: Visibility.visible else: Visibility.hidden)
