import QtQuick 2.0

Item {
  id: root

  property url icon: ""
  property string title: ""
  property string artists: ""
  property string comment: ""
  property int trackId
  property bool liked: false

  signal toggleLiked()

  PlayerTrackIcon {
    id: _icon
    anchors.verticalCenter: root.verticalCenter

    src: icon
  }

  PlayerTrackInfo {
    id: _info
    anchors.left: _icon.right
    anchors.leftMargin: 11
    width: root.width - anchors.leftMargin - _icon.width
    height: root.height

    title: root.title
    artists: root.artists
    comment: root.comment
    trackId: root.trackId
    liked: root.liked

    onToggleLiked: root.toggleLiked()
  }
}
