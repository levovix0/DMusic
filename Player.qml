import QtQuick 2.0
import api 1.0

Rectangle {
  id: root

  color: "#262626"

  property alias player: _player

  PlayerControls {
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
  }

  MediaPlayer {
    id: _player
  }

  PlayerTrack {
    x: 8
    anchors.verticalCenter: root.verticalCenter
    icon: _player.cover
    name: "Nothing"
    author: "LightFly"
    additional: "Original Mix"
  }
}
