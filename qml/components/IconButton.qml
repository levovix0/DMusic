import QtQuick 2.15
import DMusic 1.0

Icon {
  id: root

  property var style: Style.panel.icon.normal

  signal clicked()

  color: enabled? (_mouse.containsPress? style.pressedColor : _mouse.containsMouse? style.hoverColor : style.color) : (stile.unavailableColor)

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true
    onClicked: root.clicked()
  }
}
