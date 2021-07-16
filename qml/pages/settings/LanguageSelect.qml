import QtQuick 2.15
import DMusic 1.0
import "../../components"

DText {
  id: root

  property int language: Config.EnglishLanguage
  property bool selected: Config.language == language

  style: Style.block.text
  font.weight: selected? Font.Bold : Font.Light

  MouseArea {
    anchors.fill: parent

    visible: !root.selected
    cursorShape: Qt.PointingHandCursor

    onClicked: Config.language = root.language
  }
}
