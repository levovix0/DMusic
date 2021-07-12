import QtQuick 2.0
import DMusic 1.0
import ".."

DPage {
  id: root

  Row {
    id: _yandexHomePlaylists
    spacing: 25
    anchors.left: root.left
    anchors.top: root.top
    anchors.leftMargin: 25
    anchors.topMargin: 25

    Repeater {
      id: _yandexHomePlaylistsRepeater

      Component.onCompleted: {
        if (YClient.loggined()) {
          model = YClient.homePlaylistsModel()
        } else {
          YClient.logginedChanged.connect(function(loggined) {
            if (loggined) {
              model = YClient.homePlaylistsModel()
            } else {
              model = 0
            }
          })
        }
      }

      PlaylistEntry {
        playlist: element

        onPlay: YClient.playPlaylist(playlist)
      }
    }
  }
}
