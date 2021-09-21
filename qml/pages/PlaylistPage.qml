import QtQuick 2.15
import "../components"

DPage {
  id: root

  PagePlaceholder {
    anchors.centerIn: parent

    icon: "qrc:/resources/placeholders/playlist.svg"
    text: qsTr("There must be playlist")
    text2: qsTr("but there isn't")
  }
}
