import QtQuick 2.15
import DMusic 1.0
import "components"

Rectangle {
  id: root

  property url icon: ""
  property var style: Style.header.button
  signal click()
  signal pressed()

  enabled: true
  visible: enabled
  width: enabled? 50 : 0
  height: 40

  color: _mouse.containsPress? style.background.pressed: _mouse.containsMouse? style.background.hover : style.background.normal

  Icon {
    anchors.centerIn: root
    visible: root.enabled
    src: icon
    color: _mouse.containsPress? style.color.pressed: _mouse.containsMouse? style.color.hover : style.color.normal
  }

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true

    onClicked: if (enabled) { root.click(); _root.focus = true }
    onPressed: if (enabled) root.pressed()
  }
}
