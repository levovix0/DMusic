import nimqt
import nimqt/[qpushbutton, qstackedlayout, qboxlayout, qevent, qwindow]
import ..//qt/[QGraphicsDropShadowEffect, QFlags]

nimqt.init


inheritQObject(DmusicWindow, QWidget):
  var edge: int  # 8 edges (1..8), from top to top-left 
  var borderWidth: int

  override mouseMoveEvent(e: ptr QMouseEvent):
    let pos = e.localPos.toPoint
    let box = this.frameGeometry

    let left = pos.x in 0..(box.x + this.borderWidth)
    let top = pos.y in 0..(box.y + this.borderWidth)
    let right = pos.x in (box.width - this.borderWidth)..(box.width)
    let bottom = pos.y in (box.height - this.borderWidth)..(box.height)

    if left and top:
      this.setCursor(newQCursor(SizeFDiagCursor))
      this.edge = 8
    elif right and top:
      this.setCursor(newQCursor(SizeBDiagCursor))
      this.edge = 2
    elif right and bottom:
      this.setCursor(newQCursor(SizeFDiagCursor))
      this.edge = 4
    elif left and bottom:
      this.setCursor(newQCursor(SizeBDiagCursor))
      this.edge = 6
    elif left:
      this.setCursor(newQCursor(SizeHorCursor))
      this.edge = 7
    elif top:
      this.setCursor(newQCursor(SizeVerCursor))
      this.edge = 1
    elif right:
      this.setCursor(newQCursor(SizeHorCursor))
      this.edge = 3
    elif bottom:
      this.setCursor(newQCursor(SizeVerCursor))
      this.edge = 5
    else:
      this.unsetCursor()
      this.edge = 0
  
  override mousePressEvent(e: ptr QMouseEvent):
    if e.buttons == newQFlags(LeftButton):
      if this.edge != 0:
        discard this.window.windowHandle.startSystemResize(
          case this.edge
          of 1: newQFlags(TopEdge)
          of 2: newQFlags(TopEdge) | RightEdge
          of 3: newQFlags(RightEdge)
          of 4: newQFlags(RightEdge) | BottomEdge
          of 5: newQFlags(BottomEdge)
          of 6: newQFlags(BottomEdge) | LeftEdge
          of 7: newQFlags(LeftEdge)
          of 8: newQFlags(LeftEdge) | TopEdge
          else: newQFlags(LeftEdge)
        )
  
  override leaveEvent(e: ptr QEvent):
    this.unsetCursor()
  
  override eventFilter(obj: ptr QObject, e: ptr QEvent): bool:
    if obj != this and e.`type` == Enter:
      this.unsetCursor()


proc createWindow*(root: ptr QWidget): ptr QWidget =
  result = newQWidget(
    nil,
    newQFlags(Qt_WindowType.FramelessWindowHint) |
    newQFlags(Qt_WindowType.Window)
  )

  result.makeLayout:
    setAttribute(WA_NoSystemBackground)
    setAttribute(WA_TranslucentBackground)
    setObjectName(Q "window")

    - newDmusicWindow() as win:
      setObjectName(Q "windowInner")
      
      installEventFilter(win)
      setMouseTracking(true)
      win.borderWidth = 10

      setGraphicsEffect(
        block:
          let effect = newQGraphicsDropShadowEffect()
          effect.setXOffset(0)
          effect.setYOffset(0)
          effect.setColor(newQColor(0, 0, 0, 144))
          effect.setBlurRadius(10)
          effect
      )
      
      - newQHBoxLayout():
        - useObject root:
          installEventFilter(win)
