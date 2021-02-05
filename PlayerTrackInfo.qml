import QtQuick 2.0

Item {
  id: root

  property string name: ""
  property string author: ""
  property string additional: ""

  DText {
    id: _name
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 3

    text: name
    font.pixelSize: 14
    font.bold: true
  }

  DText {
    id: _author
    anchors.top: root.verticalCenter
    anchors.topMargin: 3

    text: author
    font.pixelSize: 12
    color: "#CCCCCC"
  }

  DText {
    id: _additional
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 3
    anchors.left: _name.right
    anchors.leftMargin: 5

    text: additional
    font.pixelSize: 14
    color: "#999999"
  }
}
