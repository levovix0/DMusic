import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root

  width: 25
  height: 25

  property string icon: ""
  property alias image: _icon.image
  property var style: Style.panel.icon.normal

  signal click()

  Icon {
    id: _icon
    anchors.centerIn: root

    src: icon
    color: _mouse.containsPress? root.style.pressedColor : _mouse.containsMouse? root.style.hoverColor : root.style.color
  }

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true

    onClicked: root.click()
  }
}
