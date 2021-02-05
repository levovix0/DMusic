import QtQuick 2.12
import QtQuick.Window 2.12

Window {
  id: root
  // Component.onCompleted: visible = true
  visible: true
  flags: {
    if (manualTitle) {
      flags += Qt.FramelessWindowHint
    }
  }

  width: 1280
  height: 720
  minimumWidth: 1040
  minimumHeight: 600

  property bool manualTitle: true

  title: "DMusic"

  color: "#181818"

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    root.showMinimized()
  }

  Player {
    id: _player
    width: root.width
    height: 66
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 0
  }

  Title {
    id: _title
    width: root.width
    window: root
    manual: root.manualTitle
  }
}
