import QtQuick 2.15
import "../components"

DPage {
  id: root

  PagePlaceholder {
    anchors.centerIn: parent

    icon: "qrc:/resources/placeholders/search.svg"
    text: qsTr("There must be search")
    text2: qsTr("but there isn't")
  }
}
