import QtQuick 2.0

Rectangle {
  id: root
  height: 20
  width: 200
  radius: 3

  color: "#262626"

  property string hint: ""
  property alias text: _input.text

  MouseArea {
    anchors.fill: parent
    anchors.leftMargin: 5
    anchors.rightMargin: 5

    clip: true

    cursorShape: Qt.IBeamCursor

    TextInput {
      id: _input
      anchors.fill: parent

      color: "#FFFFFF"
      font.pixelSize: root.height * 0.8
      selectByMouse: true
      selectionColor: "#627FAA"
    }

    DText {
      anchors.verticalCenter: parent.verticalCenter
      visible: _input.text == ""

      font.pixelSize: root.height * 0.7
      text: root.hint
      color: "#999999"
    }
  }
}
