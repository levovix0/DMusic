import QtQuick 2.0
import api 1.0

Item {
  id: root

  property MediaPlayer target
  width: 0
  height: 0

  Icon {
    id: _icon
    anchors.centerIn: root

    src: (target.volume <= 0.01 ||  target.muted)? "qrc:/resources/player/vol-muted.svg" : target.volume <= 0.5? "qrc:/resources/player/vol-quiet.svg" : "qrc:/resources/player/vol.svg"
    color: _mouse.containsMouse? "#FFFFFF" : "#C1C1C1"
  }

  MouseArea {
    id: _mouse
    anchors.centerIn: root
    width: 32
    height: 32

    hoverEnabled: true

    onPressed: target.muted = !target.muted
    onWheel: target.volume += 0.05 * wheel.angleDelta.y / 120
  }

  VolumeControlPanel {
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: 48
    anchors.horizontalCenterOffset: -5

    target: root.target
  }
}
