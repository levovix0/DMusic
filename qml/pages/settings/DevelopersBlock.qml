import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Developers")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 15
    Layout.maximumWidth: 250

    ColumnLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 5

      Row {
        Layout.alignment: Qt.AlignHCenter
        DText {
          text: qsTr("levovix")
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("https://github.com/levovix0")
          }
        }

        DText {
          text: qsTr(" - code, design")
        }
      }

      Row {
        Layout.alignment: Qt.AlignHCenter
        DText {
          text: qsTr("LightFly")
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("https://www.youtube.com/c/LightFlyzzz")
          }
        }

        DText {
          text: qsTr(" - design, code")
        }
      }

      Row {
        Layout.alignment: Qt.AlignHCenter
        DText {
          text: qsTr("Elidder")
        }

        DText {
          text: qsTr(" - design")
        }
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 7

      Icon {
        Layout.alignment: Qt.AlignVCenter
        width: 16
        height: 16
        src: "qrc:/resources/settings/GitHub.svg"
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/levovix0/DMusic")
        }
      }

      DText {
        Layout.alignment: Qt.AlignVCenter
        text: qsTr("GitHub")
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/levovix0/DMusic")
        }
      }
    }
  }
}
