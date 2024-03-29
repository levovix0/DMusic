import QtQuick 2.0
import QtGraphicalEffects 1.15

Image {
  id: root
  property bool rounded: true
  property real radius: 10

  antialiasing: true

  layer.enabled: rounded
  layer.effect: OpacityMask {
    maskSource: Item {
      width: root.width
      height: root.height
      Rectangle {
        anchors.fill: parent
        radius: root.radius
      }
    }
  }
}
