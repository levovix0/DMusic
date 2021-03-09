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

    DText {
      id: _yapi_state
      x: 5
      y: 50

      text: "-"
    }

    DText {
      id: _track_state
      x: 5
      y: 70

      text: "-"
    }

    DText {
      id: _track_info_state
      x: 5
      y: 90

      text: "-"
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
        _yapi_state.text = "Вход..."

        function updateUI(success) {
          _yapi_state.text = success? "Ок" : "Ошибка"
        }

        if (_settings.ym_proxyServer == "") {
          login(_settings.ym_token, updateUI)
        } else {
          loginViaProxy(_settings.ym_token, _settings.ym_proxyServer, updateUI)
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
      id: _download
      anchors.centerIn: root
      anchors.verticalCenterOffset: 40

      text: "Скачать"

      onClick: {
        if (!_yapi.isLoggined()) return

        function download(track) {
          _track_state.text = "Скачивается"
          track.download(function(success) {
            _track_state.text = success? "Ок" : "Ошибка"
          })
        }

        function downloadAll(track) {
          _track_info_state.text = "Скачивается"
          track.saveMetadata()

          function donwloaded(success) {
            _track_info_state.text = success? "Ок" : "Ошибка"
            download(track)
          }
          track.saveCover(1000, donwloaded)
        }

        function fetched(success, tracks) {
          if (success) {
            tracks.forEach(function(track) {
              downloadAll(track);
            });
          } else {
            _track_state.text = "Ошибка (нет трека)"
            _track_info_state.text = "Ошибка (нет трека)"
          }
        }

        _yapi.fetchTracks(parseInt(_id_input.text), fetched)
      }
    }

    DButton {
      id: _play
      anchors.centerIn: root
      anchors.verticalCenterOffset: 80

      text: "Прослушать"

      onClick: {
        _player.player.playYandex(parseInt(_id_input.text))
      }
    }
    Keys.onSpacePressed: _player.player.pause_or_play()
  }
}
