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
    anchors.topMargin: 30

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
      ColorSettingsBlock {}
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignTop
      Layout.minimumWidth: 550
      Layout.maximumWidth: 600
      spacing: 20

      ThemeSettingsBlock {}
      GeneralSettingsBlock {}
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignTop
      Layout.minimumWidth: 200
      Layout.maximumWidth: 250
      spacing: 20

      LanguageSettingsBlock {}
      DevelopersBlock {}
    }
  }
}
