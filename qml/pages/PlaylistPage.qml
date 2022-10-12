import QtQuick 2.15
import DMusic 1.0
import "../components"
import "../playlist"

DPage {
  id: root

  Flickable {
    id: _scroll
    anchors.fill: parent
    clip: true
    anchors.leftMargin: 20
    anchors.rightMargin: 20

    contentWidth: root.width - 40
    contentHeight: _layout.height + 40

    Column {
      id: _layout
      width: parent.width
      y: 20
      
      Repeater {
        model: PlaylistView

        TrackItem {
          width: _layout.width
          cover: objCover
          title: objTitle
          author: objAuthor
          duration: objDuration

          onPlay: {
            if (PlaylistView.ownerId != 0) AudioPlayer.playYmPlaylist(PlaylistView.id, PlaylistView.ownerId, objI)
            else AudioPlayer.playDmPlaylist(PlaylistView.id, objI)
          }
        }
      }
    }
  }
}
