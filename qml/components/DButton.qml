import QtQuick 2.15
import DMusic 1.0

Rectangle {
  id: root
  height: 24
  width: _text.width + 20
  radius: 4

  property alias text: _text.text
  property bool onPanel: false
  signal click()

  property var cs: onPanel? Style.button.background.panel : Style.button.background.normal
  color: _mouse.containsPress? cs.press : (_mouse.containsMouse? cs.hover : cs.normal)

  DText {
    id: _text
    anchors.centerIn: parent

    text: "Скачать"
  }

  MouseArea {
    id: _mouse
    anchors.fill: parent

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.click()
  }
}
