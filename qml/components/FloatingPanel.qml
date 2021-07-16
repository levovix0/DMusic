import QtQuick 2.0
import QtGraphicalEffects 1.15
import DMusic 1.0

Item {
  id: root

  property color color: Style.panel.background

  opacity: 0

  Rectangle {
    id: _background
    anchors.fill: root
    radius: 8
    color: root.color
  }

  DropShadow {
    anchors.fill: root
    radius: 16.0
    samples: 25
    color: "#40000000"
    source: _background
  }

  Triangle {
    anchors.top: root.bottom
    anchors.horizontalCenter: root.horizontalCenter

    color: root.color
  }
}
