import QtQuick 2.15
import QtGraphicalEffects 1.12
import DMusic 1.0

Item {
  id: root
  width: 115
  height: root.width + _name.height + 10

  property bool playing: false

  property real _anim_n: 0
  property real _anim2_n: 0
  property YPlaylist playlist

  signal play()
  signal pause()
  signal showOrHide()
  signal showFull()

  NumberAnimation on _anim_n {
    id: _anim
    duration: 250
    easing.type: Easing.OutQuad
  }
  function processHover() {
    _anim.from = 0
    _anim.to = 1
    _anim.restart()
  }
  function processLeave() {
    _anim.from = 1
    _anim.to = 0
    _anim.restart()
  }
  NumberAnimation on _anim2_n {
    id: _anim2
    duration: 250
    easing.type: Easing.OutQuad
  }
  function processHover2() {
    _anim2.from = 0
    _anim2.to = 1
    _anim2.restart()
  }
  function processLeave2() {
    _anim2.from = 1
    _anim2.to = 0
    _anim2.restart()
  }

  Image {
    id: _cover
    visible: false
    width: root.width
    height: root.width
    sourceSize: Qt.size(root.width, root.width)

    source: playlist == null? "qrc:/resources/player/no-cover.svg" : playlist.cover
    fillMode: Image.PreserveAspectCrop

    Rectangle {
      id: _hoverShadeEffect
      anchors.fill: parent
      color: "#000000"
      opacity: _anim_n * 0.4 + _anim2_n * 0.1
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
      onEntered: root.processHover()
      onExited: root.processLeave()

      onPressed: showOrHide()

      MouseArea {
        id: _playMouse
        anchors.centerIn: parent
        width: 30
        height: 30

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.processHover2()
        onExited: root.processLeave2()

        onPressed: playing? pause() : play()
      }
    }
  }

  Icon {
    id: _play
    anchors.centerIn: _roundCover
    opacity: _anim_n

    src: playing? "qrc:/resources/player/pause.svg" : "qrc:/resources/player/play.svg"
    color: Qt.hsla(0.14, 0.7 + _anim2_n * 0.3, 1 - _anim2_n * 0.3, 1)
    image.sourceSize: Qt.size(25, 30)
    scale: 0.7 + _anim_n * 0.1 + _anim2_n * 0.2
  }

  DropShadow {
    anchors.fill: root
    visible: _play.visible
    radius: 5.0
    samples: 25
    color: "#60000000"
    source: _play
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

    text: playlist == null? qsTr("some playlist") : playlist.name

    MouseArea {
      id: _textMouse
      anchors.fill: parent

      cursorShape: Qt.PointingHandCursor

      onPressed: showFull()
    }
  }
}
