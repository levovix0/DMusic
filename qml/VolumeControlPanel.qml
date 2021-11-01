import QtQuick 2.0
import DMusic 1.0
import "components"

FloatingPanel {
  id: root

  PlayerController {
    id: _player
  }

  VolumeSlider {
    id: _volume
    height: root.height - 69
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: 20

    value: _player.volume
    onSeek: _player.volume = value
  }
}
