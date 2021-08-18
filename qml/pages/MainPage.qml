import QtQuick 2.0
import DMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  Row {
    id: _yandexHomePlaylists
    spacing: 25
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 25
    anchors.topMargin: 25

    Repeater {
      id: _yandexHomePlaylistsRepeater

      Component.onCompleted: {
        if (YClient.loggined) {
          _yandexHomePlaylistsRepeater.model = YClient.homePlaylistsModel()
        } else {
          YClient.logginedChanged.connect(function(loggined) {
            if (loggined) {
              _yandexHomePlaylistsRepeater.model = YClient.homePlaylistsModel()
            } else {
              _yandexHomePlaylistsRepeater.model = []
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
