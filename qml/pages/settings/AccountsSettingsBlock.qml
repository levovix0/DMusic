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

    Loader {
      Layout.alignment: Qt.AlignCenter
      Layout.preferredWidth: item.width

      sourceComponent: Config.ym_token != ""? _YandexMusiclogined : _YandexMusiclogin

      Component {
        id: _YandexMusiclogined

        ColumnLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 10

          DText {
            Layout.alignment: Qt.AlignCenter

            text: qsTr("Yandex")
            color: Style.block.text.categoryColor
            font.bold: true
          }

          Item {
            clip: true
            height: _emailText.height
            width: Math.min(250, _emailText.width)

            DText {
              id: _emailText
              text: Config.ym_email
              color: _emailMouse.containsMouse? Style.block.text.darkColor : Style.block.text.color
              font.pointSize: 10.5

              Rectangle {
                visible: _emailMouse.containsMouse
                height: 1
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1
                color: Style.block.text.color
              }

              MouseArea {
                id: _emailMouse
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                  Config.ym_token = ""
                }
              }
            }

            Rectangle {
              id: _shade
              width: 10
              height: _emailText.height
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
      }

      Component {
        id: _YandexMusiclogin

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: 0
          opacity: (_mouse1.containsMouse || _mouse2.containsMouse)? 0.75 : 1

          DText {
            id: _loginButton
            style: Style.block.text
            font.pointSize: 10.5

            text: qsTr("Login to ")

            MouseArea {
              id: _mouse1
              anchors.fill: parent

              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: switcher("qrc:/qml/pages/YandexLoginPage.qml")
            }
          }

          DText {
            Layout.alignment: Qt.AlignCenter
            color: Style.block.text.categoryColor
            font.bold: true
            font.pointSize: 10.5

            text: qsTr("Yandex")

            MouseArea {
              id: _mouse2
              anchors.fill: parent

              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: switcher("qrc:/qml/pages/YandexLoginPage.qml")
            }
          }
        }
      }
    }
  }
}
