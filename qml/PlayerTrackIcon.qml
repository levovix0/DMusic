import QtQuick 2.15
import QtQml 2.15
import DMusic 1.0
import "components"

Item {
  id: root
  width: 50
  height: 50

  property url src: ""

  RoundedImage {
    id: _icon
    source: src
    anchors.fill: root
    sourceSize.width: root.width
    sourceSize.height: root.height

    fillMode: Image.PreserveAspectCrop
    clip: true
    radius: 7.5
  }

  MouseArea {
    id: _mouse
    anchors.fill: _icon
    enabled: !PlayingTrackInfo.isNone

    cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: _ppc.opened = !_ppc.opened
  }

  PopupController {
    id: _ppc
    target: _panel
    Binding { target: _ppc; property: "opened"; value: false; when: !_mouse.enabled; restoreMode: Binding.RestoreBinding }
  }

  TrackPanel {
    id: _panel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.top
    anchors.bottomMargin: 20 - _ppc.shift
    anchors.horizontalCenterOffset: 100

    triangleOffset: -anchors.horizontalCenterOffset
    triangleCenter: _panel.horizontalCenter

    ppc: _ppc
  }
}
