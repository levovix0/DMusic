import QtQuick 2.0
import DMusic 1.0

Item {
  id: root

  property bool playing: false
  property var nextMode: Settings.NextSequence
  property var loopMode: Settings.LoopNone

  signal pause_or_play()
  signal next()
  signal prev()
  signal changeLoopMode(var mode)
  signal changeNextMode(var mode)

  PlayerControlsButton {
    id: _play_pause
    anchors.centerIn: root
    width: 30
    height: 30

    icon: playing? "resources/player/pause.svg" : "resources/player/play.svg"
    onClick: pause_or_play()
  }

  PlayerControlsButton {
    id: _next
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50

    icon: "resources/player/next.svg"

    onClick: next()
  }

  PlayerControlsButton {
    id: _prev
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50

    icon: "resources/player/prev.svg"

    onClick: prev()
  }

  PlayerControlsButton {
    id: _loop
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50 + 50

    icon: loopMode == Settings.LoopTrack? "resources/player/loop-track.svg" : "resources/player/loop-playlist.svg"
    color: loopMode != Settings.LoopNone? "#FCE165" : "#C1C1C1"
    hoverColor: loopMode != Settings.LoopNone? "#CDB64E" : "#FFFFFF"
    onClick: {
      if (loopMode == Settings.LoopNone) changeLoopMode(Settings.LoopPlaylist)
      else if (loopMode == Settings.LoopPlaylist) changeLoopMode(Settings.LoopTrack)
      else changeLoopMode(Settings.LoopNone)
    }
  }

  PlayerControlsButton {
    id: _shuffle
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50 - 50

    icon: "resources/player/shuffle.svg"
    color: nextMode != Settings.NextSequence? "#FCE165" : "#C1C1C1"
    hoverColor: nextMode != Settings.NextSequence? "#CDB64E" : "#FFFFFF"
    onClick: changeNextMode(nextMode == Settings.NextSequence? Settings.NextShuffle : Settings.NextSequence)
  }
}
