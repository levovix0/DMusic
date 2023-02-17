import QtQuick 2.15
import DMusic 1.0

Rectangle {
  id: root
  height: style.height
  width: 200
  radius: style.radius

  color: style.background.normal
  border.width: style.border.width
  border.color: style.border.color.normal

  property string hint: ""
  property alias input: _input
  property alias text: _input.text

  property bool clearButton: false

  property real textRightPadding: 0

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
      anchors.rightMargin: ((clearButton && contentWidth > parent.width - _clear.width * 2)? _clear.width : 0) + root.textRightPadding
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: root.style.text.hAlign
      clip: true

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
      anchors.rightMargin: root.textRightPadding

      visible: _input.text == ""

      font.family: root.style.text.font
      font.pointSize: root.height * 0.75 * root.style.hintScale
      text: root.hint
      color: root.style.text.darkColor
    }

    MouseArea {
      id: _clear
      anchors.right: parent.right
      anchors.rightMargin: root.textRightPadding
      visible: clearButton && root.text !== ""
      height: parent.height
      width: height

      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.text = ""

      Icon {
        anchors.centerIn: parent
        src: "qrc:/resources/title/clear.svg"
        color: root.style.text.color
      }
    }
  }

  states: [
    State {
      name: "input"
      when: _input.text != "" || _input.focus == true
      PropertyChanges {
        target: root
        color: root.style.background.input
        border.color: style.border.color.input
      }
    }
  ]

  transitions: Transition {
    ColorAnimation { properties: "color"; duration: 250; easing.type: Easing.OutCubic }
  }
}
