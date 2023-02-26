import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import DMusic.Components 1.0
import YandexMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  Component.onCompleted: HomePlaylistsModel.load()

  Flickable {
    id: _scroll
    anchors.fill: parent
    clip: true
    leftMargin: 25
    bottomMargin: 25
    rightMargin: 25
    topMargin: 25

    contentWidth: root.width - 50
    contentHeight: _layout.height

    MouseArea {
      width: root.width
      height: Math.max(_layout.height, root.height)
      onClicked: GlobalFocus.item = ""

      ColumnLayout {
        id: _layout
        width: root.width
        spacing: 40

        Grid {
          Layout.preferredWidth: root.width - 50
          id: _yandexHomePlaylists

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

              onPlay: {
                if (objOwner != 0) AudioPlayer.playYmPlaylist(objId, objOwner)
                else AudioPlayer.playDmPlaylist(objId)
              }
              onShowFull: {
                PlaylistView.init(objId, objOwner)
                switcher("qrc:/qml/pages/PlaylistPage.qml")
              }
            }
          }

          move: Transition {
            NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
          }
        }
      }
    }
  }
}
