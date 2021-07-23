import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root

  property real progress: 0.3
  property string positionText: "0:00"
  property string durationText: "0:00"

  property real fullWidth: width + 14 * 2 + _position.width + _duration.width
  property real leftWidth: width / 2 + 14 + _position.width
  property real rightWidth: width / 2 + 14 + _duration.width

  signal seek(real progress)
  signal appendMs(real delta)

  PlayerLineSlider {
    progress: root.progress
    anchors.centerIn: root
    width: root.width

    onSeek: root.seek(progress)
    onAppendMs: root.appendMs(delta)
  }

  DText {
    id: _position
    anchors.verticalCenter: root.verticalCenter
    x: -width - 14

    font.pointSize: 9
    color: Style.darkHeader? "#A8A8A8" : "#808080"
    text: positionText
  }

  DText {
    id: _duration
    anchors.verticalCenter: root.verticalCenter
    x: root.width + 14

    font.pointSize: 9
    color: Style.darkHeader? "#A8A8A8" : "#808080"
    text: durationText
  }
}
