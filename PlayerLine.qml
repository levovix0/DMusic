import QtQuick 2.0

Item {
  id: root

  property real progress: 0.3
  property string progressText: "0:00"
  property string durationText: "0:00"

  signal seek(real progress)

  PlayerLineSlider {
    progress: root.progress
    anchors.centerIn: root
    width: root.width

    onSeek: root.seek(progress)
  }

  DText {
    id: _timeProgress
    anchors.verticalCenter: root.verticalCenter
    x: -width - 14

    font.pixelSize: 12
    color: "#A8A8A8"
    text: progressText
  }

  DText {
    id: _timeEnd
    anchors.verticalCenter: root.verticalCenter
    x: root.width + 14

    font.pixelSize: 12
    color: "#A8A8A8"
    text: durationText
  }
}
