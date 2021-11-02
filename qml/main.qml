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
  minimumWidth: 520 + shadowRadius * 2
  minimumHeight: 300 + shadowRadius * 2

  property real shadowRadius: (Config.isClientSideDecorations && !maximized)? 10 : 0
  property bool maximized: visibility == 4

  property bool needReadWH: false

  title: "DMusic"

  function updateConfigWidth() { Config.width = _window.width - _window.shadowRadius * 2 }
  function updateConfigHeight() { Config.height = _window.height - _window.shadowRadius * 2 }

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    _window.showMinimized()
  }
  color: "transparent"

  Component.onCompleted: {
    if (Config.width == Screen.desktopAvailableWidth && Config.height == Screen.desktopAvailableHeight) {
      visibility = 4
    } else {
      _window.width = Config.width + shadowRadius * 2
      _window.height = Config.height + shadowRadius * 2
    }

    widthChanged.connect(updateConfigWidth)
    heightChanged.connect(updateConfigHeight)
  }

  DropShadow {
    anchors.fill: _root
    enabled: Config.isClientSideDecorations && !maximized
    opacity: 0.6
    radius: shadowRadius
    samples: 20
    color: "#000000"
    source: Rectangle {
      width: _root.width
      height: _root.height
      color: "#000000"
      radius: 7.5
    }
  }

  Rectangle {
    id: _root
    width: _window.width - shadowRadius * 2
    height: _window.height - shadowRadius * 2
    x: shadowRadius
    y: shadowRadius

    color: Style.window.background
    focus: true

    MouseArea {
      anchors.fill: parent
      onClicked: _root.focus = true
    }

    PageSwitcher {
      id: _pages
      anchors.left: _root.left
      anchors.top: _title.bottom
      anchors.right: _root.right
      anchors.bottom: _player.top
    }

    Title {
      id: _title
      width: _root.width

      windowSize: Qt.size(_root.width, _root.height)
      clientSideDecorations: Config.isClientSideDecorations
      maximized: maximized
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

    Messages {
      id: _messagesReciever

      onMessage: _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": false })
      onError: _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": true })
      Component.onCompleted: init()
    }

    Player {
      id: _player
      width: _root.width
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

    Keys.onSpacePressed: AudioPlayer.pause_or_play()
    Keys.onRightPressed: AudioPlayer.next()
    Keys.onLeftPressed: AudioPlayer.prev()
    Keys.onPressed: {
      if (event.key === Qt.Key_L) _player.toggleLiked()
      else if (event.key === Qt.Key_D) AudioPlayer.next()
      else if (event.key === Qt.Key_A) AudioPlayer.prev()
    }

    layer.enabled: Config.isClientSideDecorations && visibility != 4
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: _root.width
        height: _root.height
        radius: 7.5
      }
    }
  }
}
