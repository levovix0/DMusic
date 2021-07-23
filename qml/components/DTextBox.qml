import QtQuick 2.15
import DMusic 1.0

Rectangle {
  id: root
  height: style.height
  width: 200
  radius: style.radius

  color: style.background.normal
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
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: root.style.text.hAlign

      color: root.style.text.color
      font.family: root.style.text.font
      font.pointSize: root.height * 0.75 * root.style.textScale
      selectByMouse: true
      selectionColor: "#627FAA"
    }

    DText {
      anchors.fill: _input
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: root.style.text.hAlign

      visible: _input.text == ""

      font.family: root.style.text.font
      font.pointSize: root.height * 0.75 * root.style.hintScale
      text: root.hint
      color: root.style.text.darkColor
    }
  }

  states: [
    State {
      name: "input"
      when: _input.text != "" || _input.focus == true
      PropertyChanges {
        target: root
        color: root.style.background.input
      }
    }
  ]

  transitions: Transition {
    ColorAnimation { properties: "color"; duration: 500; easing.type: Easing.OutCubic }
  }
}
