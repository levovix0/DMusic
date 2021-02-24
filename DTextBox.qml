import QtQuick 2.0

Rectangle {
  id: root
  height: 20
  width: 200
  radius: 3

  color: "#303030"

  property alias text: _input.text

  TextInput {
    id: _input
    anchors.centerIn: root
    width: root.width - 10

    color: "#FFFFFF"
    font.pixelSize: root.height * 0.8
  }
}
