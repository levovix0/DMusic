import QtQuick 2.15
import DMusic 1.0
import "../../components"

DText {
  id: root

  property int language: Config.EnglishLanguage
  property bool selected: Config.language == language

  style: Style.block.text
  font.weight: selected? Font.Bold : Font.Light

  opacity: _mouse.containsMouse? 0.75 : 1

  MouseArea {
    id: _mouse
    anchors.fill: parent

    visible: !root.selected
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: Config.language = root.language
  }
}
