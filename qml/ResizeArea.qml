import QtQuick 2.15

Item {
  id: root

  property var cursor
  property var edge

  DragHandler {
    enabled: root.enabled
    target: null

    onActiveChanged: if (active) _window.startSystemResize(edge);
    cursorShape: if (enabled) cursorShape = cursor
    dragThreshold: 0
  }

  MouseArea {
    anchors.fill: root
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: if (enabled) cursorShape = cursor
  }
}
