import QtQuick 2.0
import DMisic 1.0

Rectangle {
  id: root

  color: "#262626"

  property alias player: _player
  property alias track: _track

  PlayerControls {
    id: _controls

    anchors.horizontalCenter: root.horizontalCenter
    y: 21

    playing: _player.playing

    onPause: _player.pause()
    onPlay: _player.unpause()
  }

  PlayerLine {
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7

    progress: _player.progress
    onSeek: _player.progress = progress

    progressText: _player.formatProgress
    durationText: _player.formatDuration
  }

  MediaPlayer {
    id: _player

    loopMode: _controls.isLooping? (_controls.isLoopingPlaylist_notTrack? MediaPlayer.LoopPlaylist : MediaPlayer.LoopTrack) : MediaPlayer.LoopNone
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
    icon: _player.currentTrack.cover
    title: _player.currentTrack.title
    author: _player.currentTrack.author
    extra: _player.currentTrack.extra
  }
}
