import QtQuick 2.15
import DMisic 1.0

Item {
  id: root

  property MediaPlayer target

  Icon {
    id: _icon
    anchors.centerIn: root

    src: (target.volume <= 0.01 ||  target.muted)? "qrc:/resources/player/vol-muted.svg" : target.volume < 0.5? "qrc:/resources/player/vol-quiet.svg" : "qrc:/resources/player/vol.svg"
    color: _mouse.containsMouse? "#FFFFFF" : "#C1C1C1"
  }

  MouseArea {
    id: _bg_mouse
    anchors.horizontalCenter: root.horizontalCenter
    anchors.bottom: root.bottom
    anchors.bottomMargin: -38
    anchors.horizontalCenterOffset: -5
    width: 50
    height: 32 + 210 + 38 + 24

    hoverEnabled: true

    onExited: opened = false

    property alias opened: _ppc.opened

    VolumeControlPanel {
      id: _panel
      width: 38
      height: 210
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12 + _ppc.shift

      opacity: 0

      target: root.target
    }

    PopupController {
      id: _ppc
      target: _panel
    }

    MouseArea {
      id: _mouse
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.bottom
      anchors.verticalCenterOffset: -38
      width: 32
      height: 32

      hoverEnabled: true

      onPressed: target.muted = !target.muted
      onWheel: target.volume += 0.05 * wheel.angleDelta.y / 120
      onEntered: _bg_mouse.opened = true
    }
  }
}
