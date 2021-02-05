import QtQuick 2.0

Item {
  id: root

  property string icon: ""
  property string name: ""
  property string author: ""
  property string additional: ""

  PlayerTrackIcon {
    id: _icon
    anchors.verticalCenter: root.verticalCenter

    src: icon
  }

  PlayerTrackInfo {
    id: _info
    anchors.left: _icon.right
    anchors.leftMargin: 11

    name: root.name
    author: root.author
    additional: root.additional
  }
}
