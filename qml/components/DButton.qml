import QtQuick 2.15
import QtQuick.Controls 2.15
import DMusic 1.0

Control {
  id: root
  height: 24
  implicitWidth: _text.width + 20

  property alias text: _text.text
  property alias textColor: _text.color
  property alias radius: _background.radius
  property bool onPanel: false
  signal click()

  property var cs: onPanel? Style.button.background.panel : Style.button.background.normal

  background: Rectangle {
    id: _background
    anchors.fill: root
    radius: 4
    color: _mouse.containsPress? cs.press : (_mouse.containsMouse? cs.hover : cs.normal)
  }

  contentItem: Item {
    anchors.fill: root
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
}
