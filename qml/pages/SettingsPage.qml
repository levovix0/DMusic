import QtQuick 2.0
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../components"

DPage {
  id: root

  SettingsBlock {
    x: 20
    y: 20
    title: qsTr("Accounts")

    contentItem: ColumnLayout {
      spacing: 10

      DText {
        Layout.alignment: Qt.AlignCenter

        text: qsTr("Yandex account")
        color: Style.text.categoryColor
        font.bold: true
      }

      Loader {
        Layout.alignment: Qt.AlignCenter

        sourceComponent: YClient.loggined? _token : _login
        onLoaded: {
          Layout.preferredWidth = item.width
          Layout.preferredHeight = item.height
        }
      }
    }

    Component {
      id: _token
      DText {
        text: Config.ym_token
        color: _tokenMouse.containsMouse? Style.text.darkColor : Style.text.color

        Rectangle {
          visible: _tokenMouse.containsMouse
          height: 1
          width: parent.width
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: 1
          color: Style.text.color
        }

        MouseArea {
          id: _tokenMouse
          anchors.fill: parent

          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: YClient.unlogin()
        }
      }
    }

    Component {
      id: _login
      DButton {
        id: _loginButton
        text: qsTr("Login")
        onPanel: true
      }
    }
  }
}
