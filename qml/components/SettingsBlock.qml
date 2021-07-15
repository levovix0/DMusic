import QtQuick 2.15
import QtQuick.Controls 2.15
import DMusic 1.0

Control {
  id: root

  property string title: ""
  padding: 15
  topPadding: _title.height + 30
  bottomPadding: 20

  implicitWidth: Math.max(
    _title.width + leftPadding + rightPadding,
    implicitContentWidth + leftPadding + rightPadding
  )

  background: Rectangle {
    color: Style.block.background
    radius: Style.block.radius
    border.color: Style.block.border.color
    border.width: Style.block.border.width

    DText {
      id: _title
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 15

      text: root.title
      font.pixelSize: 18
    }
  }
}
