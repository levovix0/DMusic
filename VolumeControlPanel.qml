import QtQuick 2.0
import DMusic 1.0

FloatingPanel {
  id: root

  property AudioPlayer target

  VolumeSlider {
    id: _volume
    height: root.height - 69
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: 20

    value: target.volume
    onSeek: target.volume = value
  }
}
