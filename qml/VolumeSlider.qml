import QtQuick 2.0

Rectangle {
  id: root
  width: 6

  property real value: 0.3
  property bool sellected: _mouse.containsMouse | _mouse.pressed

  signal seek(real value)

  color: "#404040"
  radius: width / 2

  Rectangle {
    id: _progress
    anchors.left: root.left
    anchors.bottom: root.bottom
    height: root.height * value + width * (0.5 - Math.abs(value - 0.5))
    width: root.width

    radius: root.radius
    color: sellected? Style.accent : "#AAAAAA"
  }

  Rectangle {
    id: _point
    visible: root.sellected
    width: 16
    height: 16
    radius: height / 2

    anchors.horizontalCenter: root.horizontalCenter
    anchors.verticalCenter: _progress.top
    anchors.verticalCenterOffset: root.width * (0.5 - Math.abs(value - 0.5))

    color: "#FFFFFF"
  }

  Rectangle {
    height: 1
    width: 4
    anchors.verticalCenter: root.verticalCenter
    anchors.left: _point.right
    anchors.leftMargin: 1

    color: Math.abs(value - 0.5) > 0.04? "#C4C4C4" : "#505050"
  }

  Rectangle {
    height: 1
    width: 4
    anchors.verticalCenter: root.verticalCenter
    anchors.right: _point.left
    anchors.rightMargin: 1

    color: Math.abs(value - 0.5) > 0.04? "#C4C4C4" : "#505050"
  }

  MouseArea {
    id: _mouse
    anchors.centerIn: root
    width: Math.max(root.width, _point.width)
    height: root.height + _point.height

    hoverEnabled: true

    onMouseXChanged: {
      if (pressed) {
        var value = 1 - (mouseY - _point.height / 2) / root.height
        value = Math.max(0, Math.min(1, value))
        root.seek(value)
      }
    }
    onWheel: {
      root.seek(value + 0.05 * wheel.angleDelta.y / 120)
    }
  }
}
