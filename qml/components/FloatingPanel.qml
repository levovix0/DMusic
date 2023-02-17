import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0

Item {
  id: root

  property color color: Style.panel.background
  property var triangleCenter: root.horizontalCenter
  property var triangleTop: root.bottom
  property var triangleBottom: root.top
  property real triangleOffset: 0
  property real triangleRotation: 0
  property bool triangleOnTop: false

  opacity: 0

  Rectangle {
    id: _background
    anchors.fill: root
    radius: Style.panel.radius
    color: root.color
  }

  DropShadow {
    anchors.fill: root
    radius: 16.0
    samples: 30
    transparentBorder: true
    color: "#40000000"
    source: _background
  }

  Triangle {
    id: _triangle
    anchors.horizontalCenter: root.triangleCenter
    anchors.top: triangleOnTop? undefined : root.triangleTop
    anchors.bottom: triangleOnTop? root.triangleBottom : undefined
    anchors.horizontalCenterOffset: root.triangleOffset
    rotation: root.triangleRotation + (triangleOnTop? 180 : 0)

    color: root.color
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
  }
}
