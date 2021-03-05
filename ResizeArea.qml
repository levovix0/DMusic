import QtQuick 2.15

Item {
  id: root

  property var window
  property var cursor
  property var edge

  DragHandler {
    enabled: root.enabled
    target: null

    onActiveChanged: if (active) window.startSystemResize(edge);
    cursorShape: if (enabled) cursorShape = cursor
  }

  MouseArea {
    anchors.fill: root
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: if (enabled) cursorShape = cursor
  }
}
