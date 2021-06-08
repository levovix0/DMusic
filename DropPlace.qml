import QtQuick 2.0
import "external"
import DMusic 1.0

DropArea {
  id: root
  width: 20
  height: 20

  property bool hasContent: false

  MouseArea {
    id: _mouse
    anchors.fill: parent

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.dropPlace.border.radius
    color: root.containsDrag? Style.dropPlace.color.drop : (_mouse.containsMouse? Style.dropPlace.color.hover : Style.dropPlace.color.normal)
  }

  Border {
    anchors.fill: parent

    antialiasing: true
    radius: Style.dropPlace.border.radius
    strokeColor: Style.dropPlace.border.color
    strokeWidth: Style.dropPlace.border.weight
    strokeStyle: 2
    dashPattern: [3, 3 + (((width + height) * 2 - radius) % 3)]
  }
}
