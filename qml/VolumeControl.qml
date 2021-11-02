import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root
  width: _icon.width
  height: _icon.height

  MouseArea {
    id: _bg_mouse
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: 50
    height: 50 + 24 + _panel.height

    hoverEnabled: _ppc.opened
    enabled: _ppc.opened

    onExited: _ppc.opened = false

    PopupController {
      id: _ppc
      target: _panel
    }

    VolumeControlPanel {
      id: _panel
      width: 38
      height: 210
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12 + _ppc.shift
    }

    Icon {
      id: _icon
      width: 32
      height: 32
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.horizontalCenterOffset: 4

      MouseArea {
        id: _mouse
        anchors.fill: parent

        hoverEnabled: true

        onEntered: _ppc.opened = true
        onPressed: AudioPlayer.muted = !AudioPlayer.muted
        onWheel: AudioPlayer.volume += 0.05 * wheel.angleDelta.y / 120
      }

      src: (AudioPlayer.volume <= 0.01 ||  AudioPlayer.muted)? "qrc:/resources/player/vol-muted.svg" : AudioPlayer.volume < 0.5? "qrc:/resources/player/vol-quiet.svg" : "qrc:/resources/player/vol.svg"
      color: (_mouse.containsMouse)? Style.panel.icon.normal.hoverColor : Style.panel.icon.normal.color
    }
  }
}
