import QtQuick 2.15
import DMusic 1.0

Rectangle {
  id: root
  height: style.height
  width: 200
  radius: style.radius

  color: style.background
  border.width: style.border.width
  border.color: style.border.color

  property string hint: ""
  property alias text: _input.text

  property QtObject style: Style.panel.textBox

  MouseArea {
    anchors.fill: parent
    anchors.leftMargin: 5
    anchors.rightMargin: 5

    clip: true

    cursorShape: Qt.IBeamCursor

    TextInput {
      id: _input
      anchors.fill: parent

      color: root.style.text.color
      font.family: root.style.text.font
      font.pointSize: root.height * 0.75 * root.style.textScale
      selectByMouse: true
      selectionColor: "#627FAA"
    }

    DText {
      anchors.verticalCenter: parent.verticalCenter
      visible: _input.text == ""

      font.family: root.style.text.font
      font.pointSize: root.height * 0.75 * root.style.hintScale
      text: root.hint
      color: root.style.text.darkColor
    }
  }
}
