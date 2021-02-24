import QtQuick 2.0

Rectangle {
  id: root
  height: 20
  width: 100
  radius: 3

  property alias text: _text.text
  signal click()

  color: _mouse.containsPress? "#404040" : "#303030"

  DText {
    id: _text
    anchors.centerIn: parent

    text: "Скачать"
  }

  MouseArea {
    id: _mouse
    anchors.fill: parent
    onClicked: root.click()
  }
}
