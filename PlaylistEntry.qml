import QtQuick 2.15
import QtGraphicalEffects 1.12
import DMusic 1.0

Item {
  id: root
  width: 115
  height: root.width + _name.height + 10

//  property QmlPlaylist playlist

  Image {
    id: _cover
    visible: false
    width: root.width
    height: root.width
    sourceSize: Qt.size(root.width, root.width)

//    source: playlist.cover
    source: "qrc:/resources/player/no-cover.svg"
    fillMode: Image.PreserveAspectCrop
  }

  GaussianBlur {
    id: _blurCover
    visible: false
    anchors.fill: _cover

    source: _cover
    radius: _imageMouse.containsMouse? 8 : 0
    samples: 16
  }

  RoundMask {
    id: _roundCover
    anchors.fill: _blurCover

    source: _blurCover

    MouseArea {
      id: _imageMouse
      anchors.fill: parent

      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
    }
  }

  DText {
    id: _name
    anchors.left: root.left
    anchors.right: root.right
    anchors.top: _cover.bottom
    anchors.topMargin: 5

    font.pointSize: 10
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap

//    text: playlist.name
    text: "some playlist"

    MouseArea {
      id: _textMouse
      anchors.fill: parent

      cursorShape: Qt.PointingHandCursor
    }
  }
}
