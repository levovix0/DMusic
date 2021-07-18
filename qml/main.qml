import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import DMusic 1.0
import "pages"

Window {
  id: _window
  visible: true
  flags: Config.isClientSideDecorations? Qt.FramelessWindowHint | Qt.Window : Qt.Window

  width: 1280 + 20
  height: 720 + 20
  minimumWidth: 1040 + 20
  minimumHeight: 600 + 20

  property real shadowRadius: (Config.isClientSideDecorations && !maximized)? 10 : 0
  property bool maximized: visibility == 4

  title: "DMusic"

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    _window.showMinimized()
  }
  color: (Config.isClientSideDecorations && !maximized)? "transparent" : Style.window.background

  DropShadow {
    anchors.fill: root
    enabled: Config.isClientSideDecorations && !maximized
    opacity: 0.6
    radius: shadowRadius
    samples: 20
    color: "#000000"
    source: Rectangle {
      width: root.width
      height: root.height
      color: "#000000"
      radius: 7.5
    }
  }

  Rectangle {
    id: root
    width: _window.width - shadowRadius * 2
    height: _window.height - shadowRadius * 2
    x: shadowRadius
    y: shadowRadius

    color: Style.window.background
    focus: true

    MouseArea {
      anchors.fill: parent
      onClicked: root.focus = true
    }

    function autologin() {
      YClient.login(Config.ym_token, Config.ym_proxyServer)
    }

    Title {
      id: _title
      width: root.width

      windowSize: Qt.size(root.width, root.height)
      clientSideDecorations: Config.isClientSideDecorations
      maximized: maximized
    }

    PageSwitcher {
      id: _pages
      anchors.left: root.left
      anchors.top: _title.bottom
      anchors.right: root.right
      anchors.bottom: _player.top
    }

    ListModel {
      id: _messages
    }

    Column {
      spacing: 15
      anchors.bottom: _player.top
      anchors.bottomMargin: 15
      anchors.horizontalCenter: parent.horizontalCenter

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
      }

      Repeater {
        model: _messages
        Message {
          text: elementText
          details: elementDetails
          isError: elementIsError
          anchors.horizontalCenter: parent.horizontalCenter

          onClosed: _messages.remove(index)
        }
      }
    }

    Player {
      id: _player
      width: root.width
      height: 66
      anchors.bottom: parent.bottom
    }

    Rectangle {
      visible: !Style.darkHeader
      height: Style.window.border.width
      anchors.left: _player.left
      anchors.right: _player.right
      anchors.verticalCenter: _player.top

      color: Style.window.border.color
    }

    Keys.onSpacePressed: _player.player.pause_or_play()
    Keys.onRightPressed: _player.next()
    Keys.onLeftPressed: _player.prev()
    Keys.onPressed: {
      if (event.key === Qt.Key_L) _player.toglleLiked()
      else if (event.key === Qt.Key_D) _player.next()
      else if (event.key === Qt.Key_A) _player.prev()
    }

    Component.onCompleted: {
      Messages.onGotMessage.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": false })
      })
      Messages.onGotError.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": true })
      })
      Messages.reSendHistory()

      YClient.init()
      root.autologin()
    }

    layer.enabled: Config.isClientSideDecorations && visibility != 4
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: root.width
        height: root.height
        radius: 7.5
      }
    }
  }
}
