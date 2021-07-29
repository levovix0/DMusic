import QtQuick 2.0
import QtGraphicalEffects 1.0

OpacityMask {
  id: root
  property real radius: 10

  maskSource: Item {
    width: root.source.width
    height: root.source.height
    Rectangle {
      anchors.fill: parent
      radius: root.radius
    }
  }
}