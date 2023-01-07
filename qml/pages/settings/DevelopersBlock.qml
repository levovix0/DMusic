import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Source code")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 15
    Layout.maximumWidth: 250

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 7

      Icon {
        Layout.alignment: Qt.AlignVCenter
        width: 16
        height: 16

        color: Style.block.text.color
        src: "qrc:/resources/settings/GitHub.svg"

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/levovix0/DMusic")
        }
      }

      LinkText {
        Layout.alignment: Qt.AlignVCenter

        text: qsTr("GitHub")
        font.pointSize: 10.5
        font.weight: Font.Medium
        url: "https://github.com/levovix0/DMusic"
      }
    }
  }
}
