import QtQuick 2.0
import "components"

Rectangle {
  id: root

  property url icon: ""
  property color hoverColor: "#303030"
  property color pressedColor: "#202020"
  signal click()
  signal pressed()

  enabled: true
  visible: enabled
  width: enabled? 50 : 0
  height: 40

  color: _mouse.containsPress? pressedColor : _mouse.containsMouse? hoverColor : "transparent"

  Icon {
    anchors.centerIn: root
    visible: root.enabled
    src: icon
    color: "#FFFFFF"
  }

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true

    onClicked: if (enabled) root.click()
    onPressed: if (enabled) root.pressed()
  }
}
