import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Theme")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 10
    Layout.maximumWidth: 600

    RowLayout {
      Layout.alignment: Qt.AlignCenter
      spacing: 28

      ThemeSelect {
        darkTheme: true
        darkHeader: Config.darkHeader
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

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 10

      DCheckBox {
        checked: Config.isClientSideDecorations
        onCheckedChanged: Config.isClientSideDecorations = checked
        text: qsTr("Client-side decorations")
        fontSize: 10.5
      }

      DCheckBox {
        checked: Config.themeByTime
        onCheckedChanged: Config.themeByTime = checked
        text: qsTr("By time of day")
        fontSize: 10.5
      }
    }
  }
}
