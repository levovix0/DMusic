import QtQuick 2.15
import DMusic 1.0
import "components"

Rectangle {
  id: root

  color: Style.panel.background

  property alias track: _track

  function toggleLiked() {
    _currentTrack.liked = !_currentTrack.liked
  }

  function next() {
    _player.next()
  }
  function prev() {
    _player.prev()
  }

  PlayerControls {
    id: _controls

    anchors.horizontalCenter: root.horizontalCenter
    y: 21

    playing: _player.playing
    shuffle: _player.shuffle
    loop: _player.loop

    onPause_or_play: _player.playing? _player.pause() : _player.play()
    onNext: _player.next()
    onPrev: _player.prev()
    onSetShuffle: _player.shuffle = v
    onSetLoop: _player.loop = v
  }

  PlayerLine {
    id: _playerLine
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7

    progress: _currentTrack.progress
    onSeek: _currentTrack.progress = progress
    onAppendMs: _currentTrack.positionMs += delta * 1000

    positionText: _currentTrack.position
    durationText: _currentTrack.duration
  }

  PlayerController {
    id: _player
  }
  
  PlayingTrackInfo {
    id: _currentTrack
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

    VolumeControl {}
  }

  PlayerTrack {
    id: _track
    x: 8
    anchors.verticalCenter: root.verticalCenter
    width: root.width / 2 - _playerLine.leftWidth - 14 - x
    height: root.height

    icon: _currentTrack.cover
    title: _currentTrack.title
    artists: _currentTrack.artists
    comment: _currentTrack.comment
    trackId: _currentTrack.id
    liked: _currentTrack.liked

    onToggleLiked: root.toggleLiked()
  }
}
