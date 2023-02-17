import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  id: root
  title: qsTr("Accounts")
  Layout.fillWidth: true

  property var rootComponent

  ColumnLayout {
    spacing: 10
    Layout.maximumWidth: 250

    Loader {
      Layout.alignment: Qt.AlignCenter
      Layout.preferredWidth: item.width

      sourceComponent: Config.ym_token != ""? _YandexMusic_logined : _YandexMusic_login

      Component {
        id: _YandexMusic_logined

        MouseArea {
          id: _mouse
          width: _text.width
          height: _text.height

          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.ym_token = ""

          DText {
            id: _text
            Layout.alignment: Qt.AlignHCenter
            opacity: _mouse.containsMouse? 0.75 : 1
            color: Style.block.text.color
            font.bold: true
            font.pointSize: 10.5

            text: qsTr("Yandex")
          }

          Rectangle {
            visible: _mouse.containsMouse
            height: 1
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            color: Style.block.text.color
          }
        }
      }

      Component {
        id: _YandexMusic_login

        Item {
          id: _YandexMusic_login_root
          width: _text1.width + _text2.width
          height: Math.max(_text1.height, _text2.height)

          DText {
            id: _text1
            opacity: _mouse.containsMouse? 0.75 : 1
            style: Style.block.text
            font.pointSize: 10.5

            text: qsTr("Login to ")
          }

          DText {
            id: _text2
            anchors.left: _text1.right
            opacity: _mouse.containsMouse? 0.75 : 1
            color: Style.block.text.categoryColor
            font.bold: true
            font.pointSize: 10.5

            text: qsTr("Yandex")
          }

          MouseArea {
            id: _mouse
            anchors.left: _text1.left
            anchors.right: _text2.right
            height: Math.max(_text1.height, _text2.height)

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: _ppc.opened = !_ppc.opened
          }

          PopupController {
            id: _ppc
            target: _ymLoginPanel
          }

          FloatingPanel {
            id: _ymLoginPanel
            width: 250
            height: 30
            parent: root.rootComponent
            x: _YandexMusic_login_root.mapToItem(root.rootComponent, _YandexMusic_login_root.width / 2 - width / 2, 0).x
            y: _YandexMusic_login_root.mapToItem(root.rootComponent, 0, _YandexMusic_login_root.height).y + 10 - _ppc.shift
            triangleOnTop: true

            Item {
              anchors.fill: parent

              DTextBox {
                id: _token
                anchors.fill: parent
                anchors.margins: 5
                anchors.rightMargin: 30
                textRightPadding: 20
                
                hint: qsTr("Token")

                IconButton {
                  width: 20
                  height: 20
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.right: parent.right
                  
                  style: Style.window.icon.normal
                  src: "qrc:resources/settings/question.svg"
                  onClicked: Qt.openUrlExternally("https://github.com/MarshalX/yandex-music-api/discussions/513")
                }
              }

              IconButton {
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: _token.right
                anchors.leftMargin: 5
                
                style: Style.window.icon.normal
                src: "qrc:resources/settings/ok.svg"
                onClicked: {
                  Config.ym_token = _token.text
                  _ppc.opened = false
                }
              }
            }
          }
        }
      }
    }
  }
}
