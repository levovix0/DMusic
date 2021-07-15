import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0

Rectangle {
  id: root
  width: 128 + 4
  height: 72 + 4

  property bool darkTheme: true
  property bool darkHeader: true
  property color header
  property color background
  property bool sellected: (darkTheme === Config.darkTheme && darkHeader === Config.darkHeader)

  color: sellected? Style.accent : "transparent"
  radius: 9

  DropShadow {
    visible: !root.sellected
    anchors.fill: _bg

    radius: 8.0
    samples: 17
    opacity: 0.5
    color: "#000000"
    source: Rectangle {
      width: _bg.width
      height: _bg.height
      radius: 7.5
      color: Style.panel.background
    }
  }

  Rectangle {
    id: _bg
    width: 128
    height: 72
    anchors.centerIn: parent

    color: root.background

    Rectangle {
      height: 20
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top

      color: root.header
    }

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: _bg.width
        height: _bg.height
        radius: 7.5
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    visible: !sellected
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      Config.darkTheme = root.darkTheme
      Config.darkHeader = root.darkHeader
    }
  }
}
