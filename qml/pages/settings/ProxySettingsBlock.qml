import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../../components"

SettingsBlock {
  title: qsTr("Proxy")
  Layout.fillWidth: true

  ColumnLayout {
    spacing: 5
    Layout.maximumWidth: 600

    DTextBox {
      id: _server
      Layout.fillWidth: true
      
      hint: qsTr("Server (for example, https://100.100.100.100:1010)")
      onTextChanged: Config.proxyServer = text
      text: Config.proxyServer
    }

    DTextBox {
      id: _auth
      Layout.fillWidth: true
      
      hint: qsTr("Authorization")
      onTextChanged: Config.proxyAuth = text
      text: Config.proxyAuth
    }
  }
}
