import QtQuick 2.0

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

  MouseArea {
    id: _mouse
    anchors.fill: root
    enabled: root.manual

    property variant clickPos: "1, 1"

    onPressed: {
      clickPos = Qt.point(mouse.x, mouse.y)
    }

    onDoubleClicked: {
      window.visibility = window.visibility == 2 ? 4 : 2
    }

    onPositionChanged: {
      if (window.visibility == 4) { window.visibility = 2 }
      var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
      window.x += delta.x
      window.y += delta.y
    }
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

  MouseArea {
    id: _lg
    width: 6
    height: window.height
    enabled: root.manual

    cursorShape: if (manual) cursorShape = Qt.SizeHorCursor

    property variant clickPos: "1, 1"

    onPressed: {
      clickPos = Qt.point(mouse.x, mouse.y)
    }

    onPositionChanged: {
      var delta = mouse.x - clickPos.x
      var distance = window.width - delta - window.minimumWidth
      if (distance < 0) delta += distance
      window.x += delta
      window.width -= delta
    }
  }

  MouseArea {
    id: _rg
    anchors.right: root.right
    width: 6
    height: window.height
    enabled: root.manual

    cursorShape: if (manual) cursorShape = Qt.SizeHorCursor

    property variant clickPos: "1, 1"

    onPressed: {
      clickPos = Qt.point(mouse.x, mouse.y)
    }

    onPositionChanged: {
      var delta = mouse.x - clickPos.x
      var distance = window.width + delta - window.minimumWidth
      if (distance < 0) delta -= distance
      window.width += delta
    }
  }

  MouseArea {
    id: _tg
    width: window.width
    height: 6
    enabled: root.manual

    cursorShape: if (manual) cursorShape = Qt.SizeVerCursor

    property variant clickPos: "1, 1"

    onPressed: {
      clickPos = Qt.point(mouse.x, mouse.y)
    }

    onPositionChanged: {
      var delta = mouse.y - clickPos.y
      var distance = window.height - delta - window.minimumHeight
      if (distance < 0) delta += distance
      window.y += delta
      window.height -= delta
    }
  }

  MouseArea {
    id: _bg
    y: window.height - height
    width: window.width
    height: 6
    enabled: root.manual

    cursorShape: if (manual) cursorShape = Qt.SizeVerCursor

    property variant clickPos: "1, 1"

    onPressed: {
      clickPos = Qt.point(mouse.x, mouse.y)
    }

    onPositionChanged: {
      var delta = mouse.y - clickPos.y
      var distance = window.height + delta - window.minimumHeight
      if (distance < 0) delta -= distance
      window.height += delta
    }
  }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:8}
}
##^##*/
