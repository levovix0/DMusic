import QtQuick 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0

RowLayout {
  id: root
  spacing: 10

  property string text
  property bool checked: false
  property color background: Style.panel.background
  property var style: Style.block

  MouseArea {
    Layout.alignment: Qt.AlignVCenter
    width: 15
    height: 15

    cursorShape: Qt.PointingHandCursor

    onClicked: root.checked = !root.checked

    Rectangle {
      anchors.fill: parent
      visible: !root.checked

      radius: 3
      color: root.background
      border.color: style.border.color
      border.width: style.border.width
    }

    Icon {
      anchors.fill: parent
      visible: root.checked

      src: "qrc:/resources/checkbox.svg"
      color: Style.accent
    }
  }

  DText {
    Layout.alignment: Qt.AlignVCenter
    visible: text != ""
    style: root.style.text

    text: root.text

    MouseArea {
      anchors.fill: parent

      cursorShape: Qt.PointingHandCursor

      onClicked: root.checked = !root.checked
    }
  }
}
