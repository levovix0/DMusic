import QtQuick 2.0

Rectangle {
  id: root
  height: 20
  width: _text.width + 20
  radius: 3

  property alias text: _text.text
  signal click()

  color: _mouse.containsPress? "#404040" : (_mouse.containsMouse? "#303030" : "#262626")

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
