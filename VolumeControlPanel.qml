import QtQuick 2.0
import api 1.0;

Rectangle {
  id: root
  width: 38
  height: 210

  property MediaPlayer target

  radius: 8
  color: "#262626"

  Triangle {
    anchors.top: root.bottom
    anchors.horizontalCenter: root.horizontalCenter

    color: "#262626"
  }

  VolumeSlider {
    id: _volume
    height: 141
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: 20

    value: target.volume
    onSeek: target.volume = value
  }
}
