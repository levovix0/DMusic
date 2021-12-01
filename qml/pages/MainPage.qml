import QtQuick 2.15
import DMusic 1.0
import YandexMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  Component.onCompleted: HomePlaylistsModel.load()

  Grid {
    id: _yandexHomePlaylists
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: 25
    anchors.rightMargin: 25
    anchors.topMargin: 25

    columns: (width + 25) / (115 + 25)
    spacing: 25
    rowSpacing: 0
    horizontalItemAlignment: Qt.AlignHCenter

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

    move: Transition {
      NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
    }
  }
}
