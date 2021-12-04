import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "components"

FloatingPanel {
  id: root
  width: 245
  height: 265

  property PopupController ppc

  Item {
    anchors.fill: parent

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Item {
        width: root.width
        height: root.height
        Rectangle {
          anchors.fill: parent
          radius: Style.panel.sellection.radius
        }
      }
    }
  }
}
