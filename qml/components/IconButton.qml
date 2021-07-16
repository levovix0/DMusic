import QtQuick 2.15
import DMusic 1.0

Icon {
  id: root

  property var style: Style.panel.icon.normal

  signal clicked()

  color: _mouse.containsMouse? style.hoverColor : style.color
  opacity: _mouse.containsPress? 0.7 : 1

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true
    onClicked: root.clicked()
  }
}
