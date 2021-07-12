import QtQuick 2.0
//TODO: таймкоды

Rectangle {
  id: root
  height: 4

  property real progress: 0.3
  property bool sellected: _mouse.containsMouse | _mouse.pressed

  signal seek(real progress)
  signal appendMs(real delta)

  color: "#404040"
  radius: height / 2

  Rectangle {
    id: _progress
    anchors.left: root.left
    height: root.height
    width: root.width * progress

    radius: root.radius
    color: sellected? Style.accent : "#AAAAAA"
  }

  Rectangle {
    id: _point
    visible: root.sellected
    width: 12
    height: 12
    radius: height / 2

    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: _progress.right

    color: "#FFFFFF"
  }

  MouseArea {
    id: _mouse
    anchors.centerIn: root
    width: root.width + _point.width
    height: Math.max(root.height, _point.height)

    hoverEnabled: true

    onMouseXChanged: {
      if (pressed) {
        var progress = (mouseX - _point.width / 2) / root.width
        progress = Math.max(0, Math.min(1, progress))
        root.seek(progress)
      }
    }
    onWheel: {
      root.appendMs(-5 * wheel.angleDelta.y / 120)
    }
  }
}
