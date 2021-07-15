import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root

  property AudioPlayer target

  Icon {
    id: _icon
    anchors.centerIn: root

    src: (target.volume <= 0.01 ||  target.muted)? "qrc:/resources/player/vol-muted.svg" : target.volume < 0.5? "qrc:/resources/player/vol-quiet.svg" : "qrc:/resources/player/vol.svg"
    color: (_mouse.containsMouse)? "#FFFFFF" : "#C1C1C1"
  }

  MouseArea {
    id: _bg_mouse
    anchors.horizontalCenter: _mouse.horizontalCenter
    anchors.bottom: _mouse.bottom
    anchors.bottomMargin: -9
    width: 50
    height: 50 + 39 + _panel.height

    onExited: _ppc.opened = false

    hoverEnabled: true
    visible: _ppc.opened || _ppc.running

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
  }

  PopupController {
    id: _ppc
    target: _panel
  }

  MouseArea {
    id: _mouse
    anchors.centerIn: _icon
    anchors.horizontalCenterOffset: -4
    width: 32
    height: 32

    hoverEnabled: true

    onEntered: _ppc.opened = true

    onPressed: target.muted = !target.muted
    onWheel: target.volume += 0.05 * wheel.angleDelta.y / 120
  }
}
