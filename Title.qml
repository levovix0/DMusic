import QtQuick 2.15

Rectangle {
  id: root
  height: 40

  property var window
  property bool manual: true

  color: "#151515"

  Icon {
    anchors.verticalCenter: root.verticalCenter
    anchors.leftMargin: 25
    anchors.left: root.left
    src: "resources/logo.svg"
    color: "#FFFFFF"
    image.width: 13
    image.height: 16
  }

  DragHandler {
    enabled: root.manual
    onActiveChanged: if (active) window.startSystemMove();
    target: null
  }

  MouseArea {
    id: _mouse
    anchors.fill: root
    enabled: root.manual

    onDoubleClicked: window.visibility = window.visibility == 2 ? 4 : 2
  }

  TitleManualButton {
    id: _close
    anchors.right: root.right
    anchors.verticalCenter: root.verticalCenter

    icon: "resources/title/close.svg"
    hoverColor: "#E03649"

    onClick: root.window.close()
  }

  TitleManualButton {
    id: _maximize
    anchors.right: _close.left
    anchors.verticalCenter: root.verticalCenter

    icon: "resources/title/maximize.svg"

    onClick: root.window.maximize()
  }

  TitleManualButton {
    id: _minimize
    anchors.right: _maximize.left
    anchors.verticalCenter: root.verticalCenter

    icon: "resources/title/minimize.svg"

    onClick: root.window.minimize()
  }

  ResizeArea {
    id: _lg
    width: 6
    height: window.height - 12
    y: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeHorCursor
    edge: Qt.LeftEdge
  }

  ResizeArea {
    id: _rg
    anchors.right: root.right
    width: 6
    height: window.height - 12
    y: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeHorCursor
    edge: Qt.RightEdge
  }

  ResizeArea {
    id: _tg
    width: window.width - 12
    x: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeVerCursor
    edge: Qt.TopEdge
  }

  ResizeArea {
    id: _bg
    y: window.height - height
    width: window.width - 12
    x: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeVerCursor
    edge: Qt.BottomEdge
  }


  ResizeArea {
    id: _ltg
    width: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeFDiagCursor
    edge: Qt.LeftEdge | Qt.TopEdge
  }

  ResizeArea {
    id: _rtg
    anchors.right: root.right
    width: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeBDiagCursor
    edge: Qt.RightEdge | Qt.TopEdge
  }

  ResizeArea {
    id: _lbg
    y: window.height - height
    width: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeBDiagCursor
    edge: Qt.LeftEdge | Qt.BottomEdge
  }

  ResizeArea {
    id: _rbg
    anchors.right: root.right
    y: window.height - height
    width: 6
    height: 6
    enabled: root.manual

    window: root.window
    cursor: Qt.SizeFDiagCursor
    edge: Qt.RightEdge | Qt.BottomEdge
  }
}
