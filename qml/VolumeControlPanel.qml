import QtQuick 2.0
import DMusic 1.0
import "components"

FloatingPanel {
  id: root

  VolumeSlider {
    id: _volume
    height: root.height - 69
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: 20

    value: _audio_player.volume
    onSeek: _audio_player.volume = value
  }
}
