import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import "../components"

DPage {
  id: root

  Image {
    id: _background
    anchors.fill: parent
    source: "qrc:/resources/settings/login-background.png"
    smooth: true
    antialiasing: true
    fillMode: Image.PreserveAspectCrop
    clip: true
  }

  function do_login() {
    Config.ym_email = _email.text
    Config.ym_token = YClient.token(_email.text, _password.text)
    YClient.login(Config.ym_token, Config.ym_proxyServer)
    switcher("qrc:/qml/pages/SettingsPage.qml")
  }

  Control {
    anchors.centerIn: parent
    horizontalPadding: 40
    verticalPadding: 40

    background: Rectangle {
      color: Style.login.background
      radius: Style.login.backgroundRadius
    }

    contentItem: ColumnLayout {
      spacing: 18

      RowLayout {
        spacing: 0
        Layout.alignment: Qt.AlignCenter

        Image {
          Layout.alignment: Qt.AlignBottom
          source: Qt.resolvedUrl(qsTr("qrc:/resources/settings/Y.svg"))
        }

        Image {
          Layout.alignment: Qt.AlignBottom
          source: Qt.resolvedUrl(qsTr("qrc:/resources/settings/andex.svg"))
        }
      }

      DText {
        Layout.alignment: Qt.AlignCenter

        color: Style.login.text
        text: qsTr("Login to account")
        font.pointSize: 18
      }

      Rectangle {
        Layout.alignment: Qt.AlignCenter

        height: 30
        width: 250
        radius: 10

        color: Style.login.textboxBacground
        border.color: Style.login.textboxBorder
        border.width: 1

        MouseArea {
          anchors.fill: parent
          anchors.leftMargin: 5
          anchors.rightMargin: 5

          clip: true

          cursorShape: Qt.IBeamCursor

          TextInput {
            id: _email
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            color: Style.login.textboxText
            font.pointSize: 30 * 0.5 * 0.75
            selectByMouse: true
            selectionColor: "#627FAA"

            onAccepted: root.do_login()
            KeyNavigation.tab: _password
          }

          DText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            visible: _email.text == ""

            font.pointSize: 30 * 0.5 * 0.75
            text: qsTr("Email")
            color: Style.login.textboxHint
          }
        }
      }

      Rectangle {
        Layout.alignment: Qt.AlignCenter

        height: 30
        width: 250
        radius: 10

        color: Style.login.textboxBacground
        border.color: Style.login.textboxBorder
        border.width: 1

        MouseArea {
          anchors.fill: parent
          anchors.leftMargin: 5
          anchors.rightMargin: 5

          clip: true

          cursorShape: Qt.IBeamCursor

          TextInput {
            id: _password
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password

            color: Style.login.textboxText
            font.pointSize: 30 * 0.3 * 0.75
            selectByMouse: true
            selectionColor: "#627FAA"

            onAccepted: root.do_login()
            KeyNavigation.tab: _email
          }

          DText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            visible: _password.text == ""

            font.pointSize: 30 * 0.5 * 0.75
            text: qsTr("Password")
            color: Style.login.textboxHint
          }
        }
      }

      DButton {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 150
        height: 30

        text: qsTr("Login")
        cs: Style.login.buttonCs
        textColor: Style.login.buttonText
        radius: 10

        onClick: root.do_login()
      }

      DText {
        Layout.alignment: Qt.AlignCenter

        text: qsTr("Back")
        color: Style.login.backText

        MouseArea {
          anchors.fill: parent

          cursorShape: Qt.PointingHandCursor
          onClicked: switcher("qrc:/qml/pages/SettingsPage.qml")
        }
      }
    }
  }
}
