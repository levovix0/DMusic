import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Theme")
  Layout.fillWidth: true

  contentItem: ColumnLayout {
    spacing: 10
    Layout.maximumWidth: 600

    RowLayout {
      Layout.alignment: Qt.AlignCenter
      spacing: 28

      ThemeSelect {
        darkTheme: true
        darkHeader: true
        background: "#33373F"
        header: "#25282F"
      }

      ThemeSelect {
        darkTheme: false
        darkHeader: false
        background: "#F0F8FF"
        header: "#F0F8FF"

        Rectangle {
          height: 1
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 2
          anchors.rightMargin: 2
          anchors.topMargin: 19 + border.width

          color: "#D9D9D9"
        }
      }

      ThemeSelect {
        darkTheme: false
        darkHeader: true
        background: "#F0F8FF"
        header: "#25282F"
      }
    }

    DCheckBox {
      Layout.alignment: Qt.AlignHCenter

      background: Style.window.background
      checked: Config.isClientSideDecorations
      onCheckedChanged: Config.isClientSideDecorations = checked
      text: qsTr("Client-side decorations")
    }
  }
}
