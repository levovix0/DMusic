import QtQuick 2.15

DText {
  id: root

  property url url

  font.underline: _mouse.containsMouse

  MouseArea {
    id: _mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Qt.openUrlExternally(root.url)
  }
}
