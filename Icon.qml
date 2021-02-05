import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {
  id: root

  property string src: ""
  property string color: "#C1C1C1"
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
