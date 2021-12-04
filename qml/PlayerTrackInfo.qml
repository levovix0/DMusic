import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root

  property string title: ""
  property string artists: ""
  property string comment: ""
  property int trackId
  property bool liked: false

  states: [
    State {
      name: "hover"
      when: _mouse_title.containsMouse || _mouse_comment.containsMouse || _mouse_artists.containsMouse
      PropertyChanges {
        target: _fullInfo
        opacity: 1
      }
      PropertyChanges {
        target: _shade
        opacity: 0
      }
    }
  ]

  transitions: Transition {
    NumberAnimation { properties: "opacity"; duration: 250; easing.type: Easing.OutQuad; }
  }

  signal toggleLiked()

  Item {
    anchors.fill: root

    clip: true

    DText {
      id: _title
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2

      text: title
      font.pointSize: 10.5
      color: Style.panel.text.color

      MouseArea {
        id: _mouse_title
        anchors.fill: parent
        enabled: root.trackId != 0

        cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        onClicked: Clipboard.text = root.trackId
      }
    }

    DText {
      id: _comment
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2
      anchors.left: _title.right
      anchors.leftMargin: 5

      text: comment
      font.pointSize: 10.5
      color: Style.darkHeader? "#999999" : "#999999"

      MouseArea {
        id: _mouse_comment
        anchors.fill: parent

        hoverEnabled: true
      }
    }

    DText {
      id: _artists
      anchors.top: parent.verticalCenter
      anchors.topMargin: 2

      text: artists
      font.pointSize: 9
      color: Style.darkHeader? "#CCCCCC" : "#515151"

      MouseArea {
        id: _mouse_artists
        anchors.fill: parent

        hoverEnabled: true
      }
    }
  }

  Rectangle {
    id: _shade
    width: 10
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Style.panel.background }
    }
  }

  PlayerControlsButton {
    id: _like
    anchors.bottom: parent.verticalCenter
    x: Math.round(Math.min(_title.width + (_comment.text == ""? 0 : _comment.width + 2) + 5, root.width + 2))
    anchors.bottomMargin: -1

    visible: PlayingTrackInfo.hasLiked
    icon: root.liked? "qrc:/resources/player/liked.svg" : "qrc:/resources/player/like.svg"

    onClick: root.toggleLiked()
  }

  Rectangle {
    id: _fullInfo
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.right
    width: Math.max(_full_title.width + 5 + _full_comment.width + 5 - root.width, _full_artists.width + 5 - root.width)
    opacity: 0
    color: Style.panel.background
    clip: true

    DText {
      id: _full_title
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2
      x: -root.width

      text: title
      font.pointSize: 10.5
      color: Style.panel.text.color
    }

    DText {
      id: _full_comment
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2
      anchors.left: _full_title.right
      anchors.leftMargin: 5

      text: comment
      font.pointSize: 10.5
      color: Style.darkHeader? "#999999" : "#999999"
    }

    DText {
      id: _full_artists
      anchors.top: parent.verticalCenter
      anchors.topMargin: 2
      x: -root.width

      text: artists
      font.pointSize: 9
      color: Style.darkHeader? "#CCCCCC" : "#515151"
    }
  }
}
