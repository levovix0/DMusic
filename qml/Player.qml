import QtQuick 2.15
import DMusic 1.0
import "components"

Rectangle {
  id: root

  color: Style.panel.background

  property alias player: _audio_player
  property alias track: _track

  function toglleLiked() {
    _audio_player.currentTrack.setLiked(!_audio_player.currentTrack.liked)
  }
  function next() {
    _audio_player.next()
  }
  function prev() {
    _audio_player.prev()
  }

  PlayerControls {
    id: _controls

    anchors.horizontalCenter: root.horizontalCenter
    y: 21

    playing: _audio_player.state === AudioPlayer.PlayingState
    loopMode: _audio_player.loopMode
    nextMode: _audio_player.nextMode

    onPause_or_play: _audio_player.pause_or_play()
    onNext: _audio_player.next()
    onPrev: _audio_player.prev()
    onChangeLoopMode: _audio_player.loopMode = mode
    onChangeNextMode: _audio_player.nextMode = mode
  }

  PlayerLine {
    id: _playerLine
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7

    progress: _audio_player.progress
    onSeek: _audio_player.progress = progress
    onAppendMs: _audio_player.progress_ms += delta * 1000

    positionText: _audio_player.formatProgress
    durationText: _audio_player.formatDuration
  }

  AudioPlayer {
    id: _audio_player
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
    target: _audio_player
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

        triangle.anchors.horizontalCenterOffset: 85

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

    icon: _audio_player.currentTrack.cover
    title: _audio_player.currentTrack.title
    artists: _audio_player.currentTrack.artistsStr
    extra: _audio_player.currentTrack.comment
    idStr: toString(_audio_player.currentTrack.id)
    liked: _audio_player.currentTrack.liked
    isYandex: _audio_player.currentTrack.isYandex

    onToggleLiked: _audio_player.currentTrack.setLiked(liked)
  }
}
