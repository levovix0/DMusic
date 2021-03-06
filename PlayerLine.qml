import QtQuick 2.0

Item {
  id: root

  property real progress: 0.3
  property string timeProgressText: "0:00"
  property string timeEndText: "1:30"

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
