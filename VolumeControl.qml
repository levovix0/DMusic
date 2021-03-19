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
    height: 32 + 210 + 38 + 24 + shift

    hoverEnabled: true

    onExited: opeened = false

    property bool opeened: false

    onOpeenedChanged: {
      if (opeened) {
        _panel.visible = true

        _panel_anim_opacity.from = 0
        _panel_anim_opacity.to = 1

        _panel_anim_pos.from = -20
        _panel_anim_pos.to = 0

        _panel_anim_opacity.restart()
        _panel_anim_pos.restart()

        _panel_anim_opacity.finished.connect(function() {
          _panel.opacity = 1
        }, Qt.UniqueConnection)
      } else {
        _panel_anim_opacity.from = 1
        _panel_anim_opacity.to = 0


        _panel_anim_pos.from = 0
        _panel_anim_pos.to = -20

        _panel_anim_opacity.restart()
        _panel_anim_pos.restart()

        _panel_anim_opacity.finished.connect(function() {
          _panel.visible = false
          _panel.opacity = 0
        }, Qt.UniqueConnection)
      }
    }

    VolumeControlPanel {
      id: _panel
      width: 38
      height: 210
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12

      visible: false
      opacity: 0

      target: root.target

      OpacityAnimator on opacity {
        id: _panel_anim_opacity
        duration: 300
        running: false
        easing.type: Easing.OutCubic
      }
    }

    property real shift: 0

    NumberAnimation on shift {
      id: _panel_anim_pos
      duration: 300
      running: false
      easing.type: Easing.OutCubic
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
      onEntered: _bg_mouse.opeened = true
    }
  }
}
