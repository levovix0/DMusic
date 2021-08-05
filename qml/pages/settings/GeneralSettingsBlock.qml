import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("General")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 5
    Layout.maximumWidth: 600

    DCheckBox {
      background: Style.window.background
      text: qsTr("Save all tracks")
      checked: Config.ym_saveAllTracks
      onCheckedChanged: Config.ym_saveAllTracks = checked
    }
  }
}
