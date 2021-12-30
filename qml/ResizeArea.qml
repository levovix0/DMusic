import QtQuick 2.15

Item {
  id: root
  visible: enabled

  property var cursor
  property var edge

  DragHandler {
    target: null

    onActiveChanged: if (active) _window.startSystemResize(edge);
    cursorShape: cursor
    dragThreshold: 0
  }

  MouseArea {
    anchors.fill: root
    hoverEnabled: true
    cursorShape: cursor
  }
}
