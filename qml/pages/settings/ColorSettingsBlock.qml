import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Color")
  Layout.fillWidth: true

  GridLayout {
    Layout.maximumWidth: 250
    columnSpacing: 10
    rowSpacing: 15
    columns: 3

    ColorSelect {
      dark: "#FCE165"
      light: "#FFA800"
    }

    ColorSelect {
      dark: "#FC6565"
      light: "#FF2E00"
    }

    ColorSelect {
      dark: "#B5FF6C"
      light: "#4CED00"
    }

    ColorSelect {
      dark: "#60BFFF"
      light: "#00D1FF"
    }

    ColorSelect {
      dark: "#BE6CFF"
      light: "#AD00FF"
    }

    ColorSelect {
      dark: "#6865FC"
      light: "#0066FF"
    }
  }
}
