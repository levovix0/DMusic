import QtQuick 2.15
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

      function updateModel(loggined) {
        if (loggined) {
          _yandexHomePlaylistsRepeater.model = YClient.homePlaylistsModel()
        } else {
          _yandexHomePlaylistsRepeater.model = []
        }
      }

      Component.onCompleted: {
        if (YClient.loggined) {
          _yandexHomePlaylistsRepeater.model = YClient.homePlaylistsModel()
        } else {
          YClient.logginedChanged.connect(updateModel)
        }
      }

      Component.onDestruction: {
        YClient.logginedChanged.disconnect(updateModel)
      }

      PlaylistEntry {
        playlist: element

        onPlay: YClient.playYPlaylist(playlist)
        onShowFull: switcher("qrc:/qml/pages/PlaylistPage.qml")
      }
    }
  }
}
