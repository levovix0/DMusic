import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Dialogs 1.2
import DMusic 1.0

Window {
  id: _root
  visible: true
  Component.onCompleted: {
    if (manualTitle) {
      flags += Qt.FramelessWindowHint
    }
  }

  width: 1280
  height: 720
  minimumWidth: 1040
  minimumHeight: 600

  property bool manualTitle: _settings.isClientSideDecorations

  title: "DMusic"

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    _root.showMinimized()
  }
  color: "#181818"

  Rectangle {
    id: root
    width: _root.width
    height: _root.height

    color: "#181818"
    focus: true

    MouseArea {
      anchors.fill: parent
      onClicked: root.focus = true
    }

    Settings {
      id: _settings

      Component.onCompleted: {
        _yapi.autologin()
      }
    }

    YClient {
      id: _yapi

      function autologin() {
        if (_settings.ym_token == "") return
        if (_settings.ym_proxyServer == "") {
          login(_settings.ym_token, function(_){})
        } else {
          loginViaProxy(_settings.ym_token, _settings.ym_proxyServer, function(_){})
        }
      }
    }

    Player {
      id: _player
      width: root.width
      height: 66
      anchors.bottom: parent.bottom

      settings: _settings
    }

    Title {
      id: _title
      width: root.width

      window: _root
      manual: _root.manualTitle
    }

    DTextBox {
      id: _id_input
      anchors.centerIn: root
      width: root.width / 3 * 2
    }

    DButton {
      id: _play
      anchors.verticalCenter: root.verticalCenter
      anchors.verticalCenterOffset: 40
      anchors.right: root.horizontalCenter
      anchors.rightMargin: 10

      text: "Прослушать"

      onClick: {
        _player.player.play(_yapi.track(parseInt(_id_input.text)))
      }
    }

    DButton {
      id: _play_downloads
      anchors.verticalCenter: root.verticalCenter
      anchors.verticalCenterOffset: 40
      anchors.left: root.horizontalCenter
      anchors.leftMargin: 10

      text: "Прослушать скачанное"

      onClick: {
        _player.player.play(_yapi.downloadsPlaylist())
      }
    }
    Keys.onSpacePressed: _player.player.pause_or_play()
  }
}
