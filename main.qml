import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Dialogs 1.2
import yapi 1.0
import api 1.0

Window {
  id: _root
  // Component.onCompleted: visible = true
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

  property bool manualTitle: true

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

    YClient {
      id: _yapi

      function autologin() {
        _yapi_state.text = "loggining"

        function updateUI(success) {
          _yapi_state.text = success? "OK" : "Err"
        }

        if (_proxy_input.text == "") {
          login(_token_input.text, updateUI)
        } else {
          loginViaProxy(_token_input.text, _proxy_input.text, updateUI)
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

    DTextBox {
      id: _token_input
      y: 50
      x: 149
      width: root.width / 3
    }

    DTextBox {
      id: _proxy_input
      anchors.left: _token_input.right
      anchors.top: _token_input.top
      anchors.leftMargin: 20
      width: root.width / 3

      text: "socks4://193.106.58.51:4153"
    }

    DButton {
      id: _download
      anchors.centerIn: root
      anchors.verticalCenterOffset: 40

      text: "Скачать"

      onClick: {
        if (!_yapi.isLoggined()) return

        function download(track) {
          _track_state.text = "скачивается"
          track.download(function(success) {
            _track_state.text = success? "OK" : "Err"
          })
        }

        function downloadAll(track) {
          _track_info_state.text = "скачивается"
          track.saveMetadata()

          function donwloaded(success) {
            _track_info_state.text = success? "OK" : "Err"
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
            _track_state.text = "Err (нет трека)"
            _track_info_state.text = "Err (нет трека)"
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

    DButton {
      id: _login
      anchors.left: _proxy_input.right
      anchors.top: _proxy_input.top
      anchors.leftMargin: 20

      text: "Войти"

      onClick: _yapi.autologin()
    }
  }
}
