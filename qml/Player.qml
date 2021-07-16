import QtQuick 2.15
import DMusic 1.0
import "components"

Rectangle {
  id: root

  color: Style.panel.background

  property alias player: _player
  property alias track: _track

  function toglleLiked() {
    _player.currentTrack.setLiked(!_player.currentTrack.liked)
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

    playing: _player.state === AudioPlayer.PlayingState
    loopMode: _player.loopMode
    nextMode: _player.nextMode

    onPause_or_play: _player.pause_or_play()
    onNext: _player.next()
    onPrev: _player.prev()
    onChangeLoopMode: _player.loopMode = mode
    onChangeNextMode: _player.nextMode = mode
  }

  PlayerLine {
    id: _playerLine
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7

    progress: _player.progress
    onSeek: _player.progress = progress
    onAppendMs: _player.progress_ms += delta * 1000

    positionText: _player.formatProgress
    durationText: _player.formatDuration
  }

  AudioPlayer {
    id: _player
    Component.onCompleted: {
      volume = Config.volume
      nextMode = Config.nextMode
      loopMode = Config.loopMode
    }

    onVolumeChanged: Config.volume = volume
    onNextModeChanged: Config.nextMode = nextMode
    onLoopModeChanged: Config.loopMode = loopMode
  }

  RemoteMediaController {
    target: _player
  }

  Row {
    spacing: 32
    anchors.right: root.right
    anchors.verticalCenter: root.verticalCenter
    anchors.rightMargin: 27

    IconButton {
      width: 20
      height: 20
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
        anchors.bottomMargin: 42 - _dpc.shift

        player: root
      }
    }

    VolumeControl {
      width: 20
      height: 20
      target: _player
    }
  }

  PlayerTrack {
    id: _track
    x: 8
    anchors.verticalCenter: root.verticalCenter
    width: root.width / 2 - _playerLine.leftWidth - 14 - x
    height: root.height

    icon: _player.currentTrack.cover
    title: _player.currentTrack.title
    artists: _player.currentTrack.artistsStr
    extra: _player.currentTrack.extra
    idStr: _player.currentTrack.idStr
    liked: _player.currentTrack.liked

    onToggleLiked: _player.currentTrack.setLiked(liked)
  }
}
