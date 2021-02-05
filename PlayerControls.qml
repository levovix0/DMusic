import QtQuick 2.0

Item {
  id: root

  property bool playing: false
  property bool isLooping: false
  property bool isLoopingPlaylist_notTrack: true
  property bool isShuffling: false

  PlayerControlsButton {
    id: _play_pause
    anchors.centerIn: root
    width: 30
    height: 30

    icon: playing? "resources/player/pause.svg" : "resources/player/play.svg"
    onClick: playing = !playing
  }

  PlayerControlsButton {
    id: _next
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50

    icon: "resources/player/next.svg"
  }

  PlayerControlsButton {
    id: _prev
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50

    icon: "resources/player/prev.svg"
  }

  PlayerControlsButton {
    id: _loop
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50 + 50

    icon: isLoopingPlaylist_notTrack? "resources/player/loop-playlist.svg" : "resources/player/loop-track.svg"
    color: isLooping? "#FCE165" : "#C1C1C1"
    hoverColor: isLooping? "#DAAF5A" : "#FFFFFF"
    onClick: {
      if (isLooping) {
        if (isLoopingPlaylist_notTrack) {
          isLoopingPlaylist_notTrack = false
        }
        else {
          isLooping = false
          isLoopingPlaylist_notTrack = true
        }
      }
      else isLooping = true
    }
  }

  PlayerControlsButton {
    id: _shuffle
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50 - 50

    icon: "resources/player/shuffle.svg"
    color: isShuffling? "#FCE165" : "#C1C1C1"
    hoverColor: isShuffling? "#DAAF5A" : "#FFFFFF"
    onClick: isShuffling = !isShuffling
  }
}
