import QtQuick 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0

RowLayout {
  id: root
  spacing: 10

  property string text
  property bool checked: false
  property var style: Style.block
  property real fontSize: 11

  MouseArea {
    Layout.alignment: Qt.AlignVCenter
    width: 16
    height: 16

    cursorShape: Qt.PointingHandCursor

    onClicked: root.checked = !root.checked

    Rectangle {
      anchors.fill: parent
      visible: !root.checked

      radius: 3
      color: "transparent"
      border.color: style.checkBox.border.color
      border.width: style.checkBox.border.width
    }

    Icon {
      anchors.fill: parent
      visible: root.checked

      src: "qrc:/resources/checkbox.svg"
      color: style.accent
    }
  }

  DText {
    Layout.alignment: Qt.AlignVCenter
    visible: text != ""
    style: root.style.text
    font.pointSize: root.fontSize

    text: root.text

    MouseArea {
      anchors.fill: parent

      cursorShape: Qt.PointingHandCursor

      onClicked: root.checked = !root.checked
    }
  }
}
