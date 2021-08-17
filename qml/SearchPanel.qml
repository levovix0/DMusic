import QtQuick 2.15
import DMusic 1.0
import "components"

FloatingPanel {
  id: root
  height: 150

  triangleCenter: horizontalCenter
  triangleTop: top
  triangleRotation: 180

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
  }
}
