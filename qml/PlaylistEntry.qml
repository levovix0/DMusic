import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "components"

Item {
  id: root
  width: 115
  height: root.width + _name.height + 10

  property bool playing: PlayingTrackInfo.playlistId == playlistId && PlayingTrackInfo.playlistOwner == ownerId && playlistId != 0

  property real _anim_n: 0
  property real _anim2_n: 0
  property string title
  property url cover
  property int playlistId
  property int ownerId

  signal play()
  signal showOrHide()
  signal showFull()

  states: [
    State {
      name: "hover"
      when: (_imageMouse.containsMouse || playing) && !_playMouse.containsMouse
      PropertyChanges {
        target: root
        _anim_n: 1
      }

      PropertyChanges {
        target: _play
        scale: 0.8
      }
    },
    State {
      name: "hoverPlay"
      when: _playMouse.containsMouse
      PropertyChanges {
        target: root
        _anim_n: 1
        _anim2_n: 1
      }

      PropertyChanges {
        target: _play
        color: Style.accent
        scale: 1
      }
    }
  ]

  transitions: Transition {
    NumberAnimation { properties: "_anim_n, _anim2_n, scale"; duration: 250; easing.type: Easing.OutQuad; }
    ColorAnimation { target: _play; properties: "color"; duration: 250; easing.type: Easing.OutQuad; }
  }

  Image {
    id: _cover
    visible: false
    width: root.width
    height: root.width
    sourceSize: Qt.size(root.width, root.width)

    source: cover
    fillMode: Image.PreserveAspectCrop

    Rectangle {
      id: _hoverShadeEffect
      anchors.fill: parent
      color: "#000000"
      opacity: _anim_n * 0.4 + _anim2_n * 0.1
    }
  }

  DropShadow {
    anchors.fill: _roundCover
    radius: 8.0
    samples: 16
    transparentBorder: true
    color: "#40000000"
    source: _roundCover
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

      onPressed: showOrHide()

      MouseArea {
        id: _playMouse
        anchors.centerIn: parent
        width: 30
        height: 30

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: if (playing) {
          AudioPlayer.playing? AudioPlayer.pause() : AudioPlayer.play()
        } else play()
      }
    }
  }

  Icon {
    id: _play
    anchors.centerIn: _roundCover
    opacity: _anim_n

    src: (playing && AudioPlayer.playing)? "qrc:/resources/player/pause.svg" : "qrc:/resources/player/play.svg"
    color: "#FFFFFF"
    image.sourceSize: Qt.size(25, 30)
    scale: 0.7
  }

  DropShadow {
    anchors.fill: root
    visible: _play.visible
    radius: 5.0
    samples: 12
    transparentBorder: true
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

    text: title

    MouseArea {
      id: _textMouse
      anchors.fill: parent

      cursorShape: Qt.PointingHandCursor

      onPressed: showFull()
    }
  }
}
