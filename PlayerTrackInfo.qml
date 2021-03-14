import QtQuick 2.0

Item {
  id: root

  property string title: ""
  property string author: ""
  property string extra: ""

  DText {
    id: _title
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 2

    text: title
    font.pixelSize: 14
  }

  DText {
    id: _author
    anchors.top: root.verticalCenter
    anchors.topMargin: 2

    text: author
    font.pixelSize: 12
    color: "#CCCCCC"
  }

  DText {
    id: _extra
    anchors.bottom: root.verticalCenter
    anchors.bottomMargin: 2
    anchors.left: _title.right
    anchors.leftMargin: 5

    text: extra
    font.pixelSize: 14
    color: "#999999"
  }
}
