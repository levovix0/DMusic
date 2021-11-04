import QtQuick 2.15
import DMusic 1.0
import YandexMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  Component.onCompleted: HomePlaylistsModel.load()

  Row {
    id: _yandexHomePlaylists
    spacing: 25
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 25
    anchors.topMargin: 25

    Repeater {
      id: _yandexHomePlaylistsRepeater

      model: HomePlaylistsModel

      PlaylistEntry {
        title: objTitle
        cover: objCover
        playlistId: objId
        ownerId: objOwner

        onPlay: AudioPlayer.playYmPlaylist(objId, objOwner)
        onShowFull: switcher("qrc:/qml/pages/PlaylistPage.qml")
      }
    }
  }
}
