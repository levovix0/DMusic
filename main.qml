import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Dialogs 1.2
import yapi 1.0

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

      property int tries: 5

      Component.onCompleted: {
//        autologin()
      }
      function autologin() {
        _yapi_state.text = "loggining"
        if (_proxy_input.text == "") {
          login(_token_input.text)
        } else {
          login(_token_input.text, _proxy_input.text)
        }
      }

      onLoggedIn: {
        _yapi_state.text = success? "OK" : "Err"
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
        _yapi.fetchedTrack.connect(function(track) {
          console.log("track ", track.id());
          track.downloaded.connect(function(success) {
            _track_state.text = success? "OK" : "Err"
          })
          track.savedCover.connect(function(success) {
            _track_info_state.text = success? "OK" : "Err"
            _track_state.text = "downloading"
            track.download()
          })
          track.saveMetadata()
          _track_info_state.text = "downloading"
          track.saveCover()
        })
        console.log("fetching tracks by id ", _id_input.text);
        _yapi.fetchTracks(parseInt(_id_input.text))
      }
    }

    DButton {
      id: _login
      anchors.left: _proxy_input.right
      anchors.top: _proxy_input.top
      anchors.leftMargin: 20

      text: "Войти"

      onClick: {
        _yapi.autologin()
      }
    }
  }
}
