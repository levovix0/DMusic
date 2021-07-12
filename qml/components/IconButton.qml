import QtQuick 2.0

Icon {
  id: root

  property color hoverColor: "#FFFFFF"
  property color normalColor: "#C1C1C1"

  signal clicked()

  color: _mouse.containsMouse? hoverColor : normalColor
  opacity: _mouse.containsPress? 0.7 : 1

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true
    onClicked: root.clicked()
  }
}
