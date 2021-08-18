import QtQuick 2.15
import QtGraphicalEffects 1.15

// TODO: make it auto-resizible using Control

Item {
  id: root

  property url src
  property color color: "#C1C1C1"
  property alias image: _img

  Image {
    id: _img
    visible: false
    source: src
    anchors.centerIn: root
  }

  ColorOverlay {
    anchors.fill: _img
    source: _img
    color: root.color
  }
}
