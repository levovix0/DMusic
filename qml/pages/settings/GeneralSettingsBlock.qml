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
      text: qsTr("Discord presence")
      fontSize: 10.5
      checked: Config.discordPresence
      onCheckedChanged: Config.discordPresence = checked
    }

    DCheckBox {
      text: qsTr("Save all tracks")
      fontSize: 10.5
      checked: Config.ym_saveAllTracks
      onCheckedChanged: Config.ym_saveAllTracks = checked
    }
  }
}
