import QtQuick 2.0
import DMusic 1.0

Rectangle {
  id: root

  color: Style.panel.background

  property Settings settings
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

    positionText: _player.formatProgress
    durationText: _player.formatDuration
  }

  AudioPlayer {
    id: _player
    Component.onCompleted: {
      volume = settings.volume
      nextMode = settings.nextMode
      loopMode = settings.loopMode
    }

    onVolumeChanged: settings.volume = volume
    onNextModeChanged: settings.nextMode = nextMode
    onLoopModeChanged: settings.loopMode = loopMode
  }

  RemoteMediaController {
    target: _player
  }

  VolumeControl {
    target: _player
    anchors.right: root.right
    anchors.verticalCenter: root.verticalCenter
    anchors.rightMargin: 36
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
    idInt: _player.currentTrack.idInt
    liked: _player.currentTrack.liked

    onToggleLiked: _player.currentTrack.setLiked(liked)
  }
}
