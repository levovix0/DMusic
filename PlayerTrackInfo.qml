import QtQuick 2.15
import DMusic 1.0

Item {
  id: root

  property string title: ""
  property string author: ""
  property string extra: ""
  property string idInt: ""

  clip: true

  DText {
    id: _title
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 2

    text: title
    font.pixelSize: 14

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor

      Clipboard {
        id: _clipboard
      }

      onClicked: _clipboard.copy(root.idInt);
    }
  }

  DText {
    id: _author
    anchors.top: root.verticalCenter
    anchors.topMargin: 2

    text: author
    font.pixelSize: 12
    color: "#CCCCCC"
  }

  DText {
    id: _extra
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 2
    anchors.left: _title.right
    anchors.leftMargin: 5

    text: extra
    font.pixelSize: 14
    color: "#999999"
  }

  Rectangle {
    width: 10
    height: root.height
    anchors.right: root.right

    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: "#262626" }
    }
  }
}
