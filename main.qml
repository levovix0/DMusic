import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import DMusic 1.0

Window {
  id: _root
  visible: true
  Component.onCompleted: {
    if (clientSideDecorations) {
      flags += Qt.FramelessWindowHint
    }
  }

  width: 1280 + 20
  height: 720 + 20
  minimumWidth: 1040 + 20
  minimumHeight: 600 + 20

  property bool clientSideDecorations: _settings.isClientSideDecorations
  property real shadowRadius: (clientSideDecorations && !maximized)? 10 : 0
  property bool maximized: visibility == 4

  title: "DMusic"

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    _root.showMinimized()
  }
  color: (clientSideDecorations && !maximized)? "transparent" : Style.window.background

  DropShadow {
    anchors.fill: root
    enabled: clientSideDecorations && !maximized
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
    width: _root.width - shadowRadius * 2
    height: _root.height - shadowRadius * 2
    x: shadowRadius
    y: shadowRadius

    color: Style.window.background
    focus: true

    MouseArea {
      anchors.fill: parent
      onClicked: root.focus = true
    }

    Settings {
      id: _settings

      Component.onCompleted: {
        YClient.init()
        root.autologin()
      }
    }

    function afterLogin() {
      _yandexHomePlaylistsRepeater.model = YClient.homePlaylistsModel()
    }

    function autologin() {
      if (_settings.ym_token == "") return
      if (_settings.ym_proxyServer == "") {
        YClient.login(_settings.ym_token, afterLogin)
      } else {
        YClient.loginViaProxy(_settings.ym_token, _settings.ym_proxyServer, afterLogin)
      }
    }

    Title {
      id: _title
      width: root.width

      window: _root
      windowSize: Qt.size(root.width, root.height)
      clientSideDecorations: _root.clientSideDecorations
      maximized: maximized
    }

    DebugPanel {
      anchors.right: root.right
      anchors.bottom: _player.top
      anchors.rightMargin: 19
      anchors.bottomMargin: 19

      player: _player
    }

    Player {
      id: _player
      width: root.width
      height: 66
      anchors.bottom: parent.bottom

      settings: _settings
    }

    Keys.onSpacePressed: _player.player.pause_or_play()
    Keys.onRightPressed: _player.next()
    Keys.onLeftPressed: _player.prev()
    Keys.onPressed: {
      if (event.key == Qt.Key_L) _player.toglleLiked()
      else if (event.key == Qt.Key_D) _player.next()
      else if (event.key == Qt.Key_A) _player.prev()
    }

    Row {
      id: _yandexHomePlaylists
      spacing: 25
      anchors.left: root.left
      anchors.top: _title.bottom
      anchors.leftMargin: 25
      anchors.topMargin: 25

      Repeater {
        id: _yandexHomePlaylistsRepeater
        PlaylistEntry {
          playlist: element

          onPlay: YClient.playPlaylist(playlist)
        }
      }
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

    Component.onCompleted: {
      Messages.onGotMessage.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": false })
      })
      Messages.onGotError.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": true })
      })
      Messages.reSendHistory()
    }

    layer.enabled: clientSideDecorations && visibility != 4
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: root.width
        height: root.height
        radius: 7.5
      }
    }
  }
}
