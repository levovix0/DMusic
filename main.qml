import QtQuick 2.15
import QtQuick.Window 2.12
import QtQuick.Dialogs 1.2
import yapi 1.0
import api 1.0

Window {
  id: _root
  visible: true
  flags: {
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
      anchors.bottomMargin: 0
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
      anchors.centerIn: root
      anchors.verticalCenterOffset: 40

      text: "Прослушать"

      onClick: {
        _player.player.play(_yapi.track(parseInt(_id_input.text)))
      }
    }
    Keys.onSpacePressed: _player.player.pause_or_play()
  }
}
