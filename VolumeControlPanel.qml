import QtQuick 2.0
import QtGraphicalEffects 1.15
import DMisic 1.0

Item {
  id: root

  property MediaPlayer target

  Rectangle {
    id: _background
    anchors.fill: root
    radius: 8
    color: "#262626"
  }

  DropShadow {
    anchors.fill: root
    radius: 16.0
    samples: 25
    color: "#40000000"
    source: _background
  }

  Triangle {
    anchors.top: root.bottom
    anchors.horizontalCenter: root.horizontalCenter

    color: "#262626"
  }

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
