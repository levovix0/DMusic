import QtQuick 2.0

Item {
  id: root

  property string icon: ""
  property string title: ""
  property string author: ""
  property string extra: ""

  PlayerTrackIcon {
    id: _icon
    anchors.verticalCenter: root.verticalCenter

    src: icon
  }

  PlayerTrackInfo {
    id: _info
    anchors.left: _icon.right
    anchors.leftMargin: 11

    title: root.title
    author: root.author
    extra: root.extra
  }
}
