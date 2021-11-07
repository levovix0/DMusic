import QtQuick 2.0
import QtGraphicalEffects 1.15

OpacityMask {
  id: root
  property real radius: 7.5

  maskSource: Item {
    width: root.source.width
    height: root.source.height
    Rectangle {
      anchors.fill: parent
      radius: root.radius
    }
  }
}
