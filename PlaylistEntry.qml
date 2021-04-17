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

    Rectangle {
      id: _hoverShadeEffect
      anchors.fill: parent
      color: "#000000"
      opacity: 0

      OpacityAnimator {
        target: _hoverShadeEffect
        id: _anim_opacity
        duration: 300
        easing.type: Easing.OutCubic
      }
    }
    function processHover() {
      _anim_opacity.from = 0
      _anim_opacity.to = 0.4
      _anim_opacity.restart()
    }
    function processLeave() {
      _anim_opacity.from = 0.4
      _anim_opacity.to = 0
      _anim_opacity.restart()
    }
  }

  RoundMask {
    id: _roundCover
    anchors.fill: _cover

    source: _cover

    MouseArea {
      id: _imageMouse
      anchors.fill: parent

      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: _cover.processHover()
      onExited: _cover.processLeave()
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
