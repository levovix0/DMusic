import QtQuick 2.0
import "../external"
import DMusic 1.0

// Перетаскивание ИЗ DropPlace

DropArea {
  id: root
  width: 20
  height: 20

  property bool hasContent: false
  property string filter: "*"

  property url content
  onEntered: {
    if (!drag.hasUrls) return
    var a = drag.urls[0]
    //TODO: filter
    drag.accept(Qt.LinkAction)
  }
  onDropped: {
    hasContent = true
    content = drop.urls[0]
  }

  MouseArea {
    id: _mouse
    anchors.fill: parent
    z: 1

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      content = _dialog.openFile(root.filter)
      hasContent = content != ""
    }
  }

  Rectangle {
    anchors.fill: parent
    z: 1
    radius: Style.dropPlace.border.radius
    color: root.containsDrag? Style.dropPlace.color.drop : (_mouse.containsMouse? Style.dropPlace.color.hover : Style.dropPlace.color.normal)
  }

  Border {
    anchors.fill: parent
    z: 1

    antialiasing: true
    radius: Style.dropPlace.border.radius
    strokeColor: Style.dropPlace.border.color
    strokeWidth: Style.dropPlace.border.weight
    strokeStyle: 2
    dashPattern: [3, 3 + (((width + height) * 2 - radius) % 3)]
  }

  DFileDialog {
    id: _dialog
  }
}
