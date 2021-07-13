import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../components"
import "settings"

DPage {
  id: root

  DText {
    id: _label
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: root.top
    anchors.topMargin: 40

    font.pointSize: 28

    text: qsTr("Settings")
  }

  RowLayout {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: _label.bottom
    anchors.topMargin: 40

    spacing: 20
    ColumnLayout {
      Layout.alignment: Qt.AlignTop
      Layout.minimumWidth: 200
      Layout.maximumWidth: 250
      spacing: 20

      AccountsSettingsBlock { switcher: root.switcher }

      SettingsBlock {
        title: qsTr("Developers")
        Layout.fillWidth: true
      }
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignTop
      Layout.minimumWidth: 550
      Layout.maximumWidth: 600
      spacing: 20

      SettingsBlock {
        title: qsTr("Theme")
        Layout.fillWidth: true
      }

      SettingsBlock {
        title: qsTr("General")
        Layout.fillWidth: true
      }
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignTop
      Layout.minimumWidth: 200
      Layout.maximumWidth: 250
      spacing: 20

      SettingsBlock {
        title: qsTr("Language")
        Layout.fillWidth: true
      }

      SettingsBlock {
        title: qsTr("Color")
        Layout.fillWidth: true
      }
    }
  }
}
