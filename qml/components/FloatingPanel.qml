import QtQuick 2.15
import Qt5Compat.GraphicalEffects
import DMusic 1.0

Item {
  id: root

  property color color: Style.panel.background
  property var triangleCenter: root.horizontalCenter
  property var triangleTop: root.bottom
  property real triangleOffset: 0
  property real triangleRotation: 0

  opacity: 0

  Rectangle {
    id: _background
    anchors.fill: root
    radius: 7.5
    color: root.color
  }

  DropShadow {
    anchors.fill: root
    radius: 16.0
    transparentBorder: true
    color: "#40000000"
    source: _background
  }

  Triangle {
    id: _triangle
    anchors.horizontalCenter: root.triangleCenter
    anchors.top: root.triangleTop
    anchors.horizontalCenterOffset: root.triangleOffset
    rotation: root.triangleRotation

    color: root.color
  }
}
