import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "components"

FloatingPanel {
  id: root
  width: 245
  height: 265

  property PopupController ppc

  Item {
    anchors.fill: parent

    RoundedImage {
      id: _icon
      source: (ppc.opened || ppc.running)? PlayingTrackInfo.hqCover : ""
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: 15
      anchors.topMargin: 15
      width: 180
      height: 180
      sourceSize.width: 180
      sourceSize.height: 180

      fillMode: Image.PreserveAspectCrop
      clip: true
      radius: 5

      MouseArea {
        anchors.fill: parent
        enabled: ppc.opened && PlayingTrackInfo.originalUrl.toString().length > 0

        cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Qt.openUrlExternally(PlayingTrackInfo.originalUrl)
      }
    }

    Column {
      width: 20
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 15
      anchors.topMargin: 20
      spacing: 18

      PlayerControlsButton {
        icon: PlayingTrackInfo.liked? "qrc:/resources/player/liked.svg" : "qrc:/resources/player/like.svg"
        property bool value: PlayingTrackInfo.liked
        property string shortcut: "L"
        property var action: function() {
          PlayingTrackInfo.liked = !PlayingTrackInfo.liked
        }

        width: 20
        height: 20

        style: value? Style.panel.icon.accent : Style.panel.icon.normal
        onClick: {
          action()
          ppc.opened = false
        }

        Shortcut {
          sequence: parent.shortcut
          context: Qt.ApplicationShortcut
          onActivated: action()
        }
      }

      PlayerControlsButton {
        icon: "qrc:/resources/player/dislike.svg"
        property bool value: PlayingTrackInfo.disliked
        property string shortcut: "Ctrl+L"
        property var action: function() {
          PlayingTrackInfo.disliked = !PlayingTrackInfo.disliked
        }

        width: 20
        height: 20

        style: value? Style.panel.icon.accent : Style.panel.icon.normal
        onClick: {
          action()
          ppc.opened = false
        }

        Shortcut {
          sequence: parent.shortcut
          context: Qt.ApplicationShortcut
          onActivated: action()
        }
      }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Item {
        width: root.width
        height: root.height
        Rectangle {
          anchors.fill: parent
          radius: Style.panel.sellection.radius
        }
      }
    }
  }
}
