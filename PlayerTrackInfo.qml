import QtQuick 2.15
import DMusic 1.0

Item {
  id: root

  property string title: ""
  property string author: ""
  property string extra: ""
  property string idInt: ""
  property bool liked: false

  signal toggleLiked(bool liked)
  //TODO: показывать полное название трека при наведении

  Item {
    anchors.fill: root

    clip: true

    DText {
      id: _title
      anchors.bottom: parent.verticalCenter
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
      anchors.top: parent.verticalCenter
      anchors.topMargin: 2

      text: author
      font.pixelSize: 12
      color: "#CCCCCC"
    }

    DText {
      id: _extra
      anchors.bottom: parent.verticalCenter
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
      anchors.right: parent.right

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: "#262626" }
      }
    }
  }

  PlayerControlsButton {
    id: _like
    anchors.bottom: parent.verticalCenter
    x: Math.round(Math.min(_title.width + (_extra.text == ""? 0 : _extra.width + 2) + 5, root.width + 2))
    anchors.bottomMargin: -1
    visible: idInt != ""

    icon: liked? "resources/player/liked.svg" : "resources/player/like.svg"

    onClick: toggleLiked(!liked)
  }
}
