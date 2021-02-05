import QtQuick 2.0

Item {
  id: root
  width: 50
  height: 50

  property string src: ""

  RoundedImage {
    id: _icon
    source: src
    anchors.fill: root
    sourceSize.width: root.width
    sourceSize.height: root.height

    fillMode: Image.PreserveAspectCrop
    clip: true
    radius: 8
  }
}
