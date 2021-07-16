import QtQuick 2.0
import DMusic 1.0

Item {
  id: root

  property bool playing: false
  property int nextMode: Config.NextSequence
  property int loopMode: Config.LoopNone

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

    icon: playing? "qrc:/resources/player/pause.svg" : "qrc:/resources/player/play.svg"
    onClick: pause_or_play()
  }

  PlayerControlsButton {
    id: _next
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50

    icon: "qrc:/resources/player/next.svg"

    onClick: next()
  }

  PlayerControlsButton {
    id: _prev
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50

    icon: "qrc:/resources/player/prev.svg"

    onClick: prev()
  }

  PlayerControlsButton {
    id: _loop
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50 + 50

    icon: loopMode == Config.LoopTrack? "qrc:/resources/player/loop-track.svg" : "qrc:/resources/player/loop-playlist.svg"
    style: loopMode != Config.LoopNone? Style.panel.icon.accent : Style.panel.icon.normal
    onClick: {
      if (loopMode == Config.LoopNone) changeLoopMode(Config.LoopPlaylist)
      else if (loopMode == Config.LoopPlaylist) changeLoopMode(Config.LoopTrack)
      else changeLoopMode(Config.LoopNone)
    }
  }

  PlayerControlsButton {
    id: _shuffle
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50 - 50

    icon: "qrc:/resources/player/shuffle.svg"
    style: nextMode != Config.NextSequence? Style.panel.icon.accent : Style.panel.icon.normal
    onClick: changeNextMode(nextMode == Config.NextSequence? Config.NextShuffle : Config.NextSequence)
  }
}
