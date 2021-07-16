import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Language")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 5
    Layout.maximumWidth: 250

    LanguageSelect {
      Layout.alignment: Qt.AlignHCenter
      text: qsTr("English")
      language: Config.EnglishLanguage
    }

    LanguageSelect {
      Layout.alignment: Qt.AlignHCenter
      text: qsTr("Russian")
      language: Config.RussianLanguage
    }
  }
}
