import QtQuick 2.0
import "components"

Item {
  id: root
  width: 50
  height: 50

  property url src: ""
  property url originalUrl: ""

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

  MouseArea {
    anchors.fill: _icon
    enabled: (src.toString().length > 0) && (src.toString().slice(0, 4) !== "qrc:")

    cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: Qt.openUrlExternally(originalUrl)
  }
}
