import QtQuick 2.15
import DMusic 1.0
import YandexMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  HomePlaylistsModel {
    id: _homePlaylists
    
    Component.onCompleted: load()
  }

  Row {
    id: _yandexHomePlaylists
    spacing: 25
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 25
    anchors.topMargin: 25

    Repeater {
      id: _yandexHomePlaylistsRepeater

      model: _homePlaylists

      PlaylistEntry {
        title: objTitle
        cover: objCover

        // onPlay: YClient.playYPlaylist(playlist)
        onShowFull: switcher("qrc:/qml/pages/PlaylistPage.qml")
      }
    }
  }
}
