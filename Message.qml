import QtQuick 2.0
//TODO: делать многострочными слишком большие сообщения

Rectangle {
  id: root
  width: _text.width + 30
  height: _text.height + 10
  radius: 5

  property string text: ""
  property string details: ""
  property bool isError: false

  signal closed()

  color: isError? "#E37575" : "#262626"

  DText {
    id: _text
    anchors.centerIn: parent

    property bool showDetails: false

    text: showDetails? root.details : root.text
    color: root.isError? "#181818" : "#C1C1C1"
    font.pixelSize: 16
  }

  MouseArea {
    anchors.fill: parent

    hoverEnabled: true
    onReleased: if (root.details !== "") _text.showDetails = !_text.showDetails
    onExited: if (!_text.showDetails) closed()
  }
}
