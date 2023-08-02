import nimqt
import ../qt/[QFlags]

const titleHeight = 40


nimqt.init


inheritQObject(DmusicWindowHeader, QWidget):
  override mouseMoveEvent(e: ptr QMouseEvent):
    if e.buttons == newQFlags(LeftButton):
      discard this.window.windowHandle.startSystemMove()

  override enterEvent(e: ptr QEvent):
    this.unsetCursor


proc createWindowHeader*(): ptr QWidget =
  result = newDmusicWindowHeader()
  result.makeLayout:
    setObjectName(Q "windowHeader")
    setMouseTracking(true)
    resize(100, titleHeight)
    setSizePolicy(Expanding, Expanding)
