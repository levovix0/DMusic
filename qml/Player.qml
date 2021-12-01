import QtQuick 2.15
import QtQml 2.15
import DMusic 1.0
import "components"

Rectangle {
  id: root

  color: Style.panel.background

  property alias track: _track

  function toggleLiked() {
    PlayingTrackInfo.liked = !PlayingTrackInfo.liked
  }

  function next() {
    AudioPlayer.next()
  }
  function prev() {
    AudioPlayer.prev()
  }

  PlayerControls {
    id: _controls

    anchors.horizontalCenter: root.horizontalCenter
    y: 21

    playing: AudioPlayer.playing
    shuffle: AudioPlayer.shuffle
    loop: AudioPlayer.loop

    onPause_or_play: AudioPlayer.playing? AudioPlayer.pause() : AudioPlayer.play()
    onNext: AudioPlayer.next()
    onPrev: AudioPlayer.prev()
    onSetShuffle: AudioPlayer.shuffle = v
    onSetLoop: AudioPlayer.loop = v
  }

  PlayerLine {
    id: _playerLine
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7

    progress: PlayingTrackInfo.progress
    onSeek: PlayingTrackInfo.progress = progress
    onAppendMs: PlayingTrackInfo.positionMs += delta * 1000

    positionText: PlayingTrackInfo.position
    durationText: PlayingTrackInfo.duration
  }

  Row {
    spacing: 20
    anchors.right: root.right
    anchors.verticalCenter: root.verticalCenter
    anchors.rightMargin: 24

    IconButton {
      width: 32
      height: 32
      src: "qrc:/resources/player/debug.svg"
      visible: root.width >= 700
      onClicked: _dpc.opened = !_dpc.opened

      PopupController {
        id: _dpc
        target: _debug
      }

      DebugPanel {
        id: _debug
        anchors.right: parent.right
        anchors.bottom: parent.top
        anchors.rightMargin: -58
        anchors.bottomMargin: 30 - _dpc.shift

        triangleOffset: -73
        triangleCenter: _debug.right

        player: root
      }
    }

    IconButton {
      width: 32
      height: 32
      src: PlayingTrackInfo.saved? "qrc:/resources/player/downloaded.svg" : "qrc:/resources/player/download.svg"
      style: PlayingTrackInfo.saved? Style.panel.icon.accent : Style.panel.icon.normal
      
      onClicked: PlayingTrackInfo.saved? (_dpc2.opened = !_dpc2.opened) : PlayingTrackInfo.save()

      Drag.mimeData: { "text/uri-list": PlayingTrackInfo.file }
      Drag.active: _downloadDrag.active
      Drag.supportedActions: Qt.CopyAction | Qt.LinkAction
      Drag.dragType: Drag.Automatic

      DragHandler {
        id: _downloadDrag
        enabled: PlayingTrackInfo.saved
        target: null
      }

      Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: -9
        width: 14
        height: 18 * PlayingTrackInfo.saveProgress
        clip: true

        Icon {
          id: _downloadProgress
          anchors.bottom: parent.bottom
          width: 14
          height: 18

          src: "qrc:/resources/player/download.svg"
          color: Style.panel.icon.accent.color
        }
      }

      PopupController {
        id: _dpc2
        target: _downloadPanel
        Binding { target: _dpc2; property: "opened"; value: false; when: !PlayingTrackInfo.saved; restoreMode: Binding.RestoreBinding }
      }

      DownloadPanel {
        id: _downloadPanel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 30 - _dpc2.shift
        anchors.horizontalCenterOffset: -50

        triangleOffset: -anchors.horizontalCenterOffset
        triangleCenter: _downloadPanel.horizontalCenter

        ppc: _dpc2
      }
    }

    VolumeControl {}
  }

  PlayerTrack {
    id: _track
    x: 8
    anchors.verticalCenter: root.verticalCenter
    width: root.width / 2 - _playerLine.leftWidth - 14 - x
    height: root.height

    icon: PlayingTrackInfo.cover
    originalUrl: PlayingTrackInfo.originalUrl
    title: PlayingTrackInfo.title
    artists: PlayingTrackInfo.artists
    comment: PlayingTrackInfo.comment
    trackId: PlayingTrackInfo.id
    liked: PlayingTrackInfo.liked

    onToggleLiked: root.toggleLiked()
  }
}
