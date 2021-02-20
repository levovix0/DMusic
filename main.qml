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

    Yapi {
      id: _yapi
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

    Rectangle {
      id: _input_r
      anchors.centerIn: root
      height: 20
      width: root.width * 0.7
      radius: 3

      color: "#303030"

      TextInput {
        id: _input
        anchors.verticalCenter: _input_r
        width: _input_r.width - x * 2
        x: 5

        color: "#FFFFFF"
        font.pixelSize: _title.height * 0.4
      }
    }

    Dialog {
        id: _message
        title: "O_o"

        function show(str) {
          title = str
          visible = true
        }
    }

    Rectangle {
      id: _download
      anchors.centerIn: root
      anchors.verticalCenterOffset: 40
      height: 20
      width: 100
      radius: 3

      color: _mouse.containsPress? "#404040" : "#303030"

      DText {
        anchors.centerIn: parent

        text: "Скачать"
      }

      MouseArea {
        id: _mouse
        anchors.fill: parent
        onClicked: {
//          _yapi.download(_input.text)
          _message.show(_yapi.test(_input.text))
        }
      }
    }
  }
}
