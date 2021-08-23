import QtQuick 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import "components"

MouseArea {
  id: root
  width: _row.implicitWidth
  height: _row.implicitHeight

  property var style: selected? Style.panel.icon.accent : Style.panel.icon.normal
  property bool selected: false
  property string text
  property url icon

  property color color: containsMouse? style.hoverColor : style.color

  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor
  onClicked: selected = !selected

  RowLayout {
    id: _row
    anchors.fill: parent
    spacing: 4

    Icon {
      width: 14
      height: 14

      src: root.icon
      color: root.color
    }

    DText {
      Layout.alignment: Qt.AlignVCenter
      style: Style.panel.text
      font.pointSize: 9

      text: root.text
      color: root.color
    }
  }
}

