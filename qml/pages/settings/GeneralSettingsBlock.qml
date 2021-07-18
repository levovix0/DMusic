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
      text: qsTr("Download all track's audios")
      checked: Config.ym_downloadMedia
      onCheckedChanged: Config._ym_downloadMedia = checked
    }

    DCheckBox {
      background: Style.window.background
      text: qsTr("Download all track's covers")
      checked: Config.ym_downloadMedia
      onCheckedChanged: Config._ym_saveCover = checked
    }

    DCheckBox {
      background: Style.window.background
      text: qsTr("Download all track's metadata")
      checked: Config.ym_downloadMedia
      onCheckedChanged: Config._ym_saveInfo = checked
    }
  }
}
