import QtQuick 2.0
import DMusic 1.0

Item {
  id: root

  property bool playing
  property bool shuffle
  property int loop

  signal pause_or_play()
  signal next()
  signal prev()
  signal setShuffle(bool v)
  signal setLoop(int v)

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
    id: _shuffle
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: -50 - 50

    icon: "qrc:/resources/player/shuffle.svg"
    style: shuffle? Style.panel.icon.accent : Style.panel.icon.normal
    onClick: setShuffle(!shuffle)
  }

  PlayerControlsButton {
    id: _loop
    anchors.verticalCenter: root.verticalCenter
    anchors.horizontalCenter: root.horizontalCenter
    anchors.horizontalCenterOffset: 50 + 50

    icon: loop == 2? "qrc:/resources/player/loop-track.svg" : "qrc:/resources/player/loop-playlist.svg"
    style: loop == 0? Style.panel.icon.normal : Style.panel.icon.accent
    onClick: setLoop((loop + 1) % 3)
  }
}
