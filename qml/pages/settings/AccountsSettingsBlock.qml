import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Accounts")
  Layout.fillWidth: true

  property var switcher

  ColumnLayout {
    spacing: 10
    Layout.maximumWidth: 250
    clip: true

    DText {
      Layout.alignment: Qt.AlignCenter

      text: qsTr("Yandex")
      color: Style.block.text.categoryColor
      font.bold: true
    }

    Loader {
      Layout.alignment: Qt.AlignCenter
      Layout.preferredWidth: item.width

      sourceComponent: YClient.loggined? _token : _login

      Component {
        id: _token
        Item {
          clip: true
          height: _token_text.height
          width: Math.min(250, _token_text.width)

          DText {
            id: _token_text
            text: Config.ym_email
            color: _tokenMouse.containsMouse? Style.block.text.darkColor : Style.block.text.color

            Rectangle {
              visible: _tokenMouse.containsMouse
              height: 1
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              anchors.verticalCenterOffset: 1
              color: Style.block.text.color
            }

            MouseArea {
              id: _tokenMouse
              anchors.fill: parent

              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: {
                Config.ym_token = ""
                YClient.unlogin()
              }
            }
          }

          Rectangle {
            id: _shade
            width: 10
            height: _token_text.height
            anchors.right: parent.right
            visible: parent.width >= 250

            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0.0; color: "transparent" }
              GradientStop { position: 1.0; color: Style.block.background }
            }
          }
        }
      }

      Component {
        id: _login
        DButton {
          id: _loginButton
          text: qsTr("Login")
          onPanel: true

          onClick: switcher("qrc:/qml/pages/YandexLoginPage.qml")
        }
      }
    }
  }
}
