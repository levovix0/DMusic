import QtQuick 2.0

Item {
  id: root

  property var progress: 0.3
  property string timeProgressText: "0:00"
  property string timeEndText: "1:30"

  PlayerLineSlider {
    progress: root.progress
    anchors.centerIn: root
    width: root.width
  }

  DText {
    id: _timeProgress
    anchors.verticalCenter: root.verticalCenter
    x: -width - 14

    font.pixelSize: 12
    color: "#A8A8A8"
    text: timeProgressText
  }

  DText {
    id: _timeEnd
    anchors.verticalCenter: root.verticalCenter
    x: root.width + 14

    font.pixelSize: 12
    color: "#A8A8A8"
    text: timeEndText
  }
}
