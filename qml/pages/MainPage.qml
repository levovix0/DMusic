import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import YandexMusic 1.0
import "qrc:/qml"

DPage {
  id: root

  Component.onCompleted: HomePlaylistsModel.load()

  ScrollView {
    id: _scroll
    anchors.fill: parent
    clip: true
    leftPadding: 25
    bottomPadding: 25
    rightPadding: 25
    topPadding: 25

    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    MouseArea {
      width: root.width
      height: _layout.height
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

              onPlay: AudioPlayer.playYmPlaylist(objId, objOwner)
              onShowFull: switcher("qrc:/qml/pages/PlaylistPage.qml")
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
