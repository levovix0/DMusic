import QtQuick 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import YandexMusic 1.0
import "components"

FloatingPanel {
  id: root
  height: _column.implicitHeight + (root.text == ""? 40 : 20)

  property string text

  signal changeText(string text)

  triangleCenter: horizontalCenter
  triangleTop: top
  triangleRotation: 180

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
  }

  onTextChanged: {
    SearchModel.search(root.text)
  }

  ColumnLayout {
    id: _column
    anchors.centerIn: parent
    width: root.width - 40

    spacing: 15

    DText {
      Layout.alignment: Qt.AlignHCenter
      color: Style.panel.text.color
      visible: SearchModel.nothingFound && root.text != ""
      text: qsTr("Nothing found")
    }

    Loader {
      sourceComponent: root.text == ""? _hisroty : _searchResults
    }

    Row {
      visible: false
      topPadding: 5
      leftPadding: spacing - 20
      rightPadding: spacing - 20
      spacing: Math.ceil((root.width - _tracks.width - _albums.width - _artists.width) / 4)

      SearchFilterToggle {
        id: _tracks
        text: qsTr("Tracks")
        icon: "qrc:/resources/search/track.svg"
      }

      SearchFilterToggle {
        id: _albums
        text: qsTr("Albums")
        icon: "qrc:/resources/search/album.svg"
      }

      SearchFilterToggle {
        id: _artists
        text: qsTr("Artists")
        icon: "qrc:/resources/search/artist.svg"
      }
    }
  }

  Component {
    id: _hisroty

    Column {
      spacing: 15
      width: root.width

      Repeater {
        enabled: root.text
        model: SearchHistory

        MouseArea {
          width: root.width - 40
          height: 14
          clip: true

          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            root.changeText(element)
            SearchHistory.savePromit(element)
          }

          Icon {
            id: _icon
            width: 14
            height: 14

            src: "qrc:/resources/search/history.svg"
            color: parent.containsMouse? Style.panel.text.darkColor : Style.panel.text.color
          }

          DText {
            x: 24
            anchors.verticalCenter: parent.verticalCenter

            style: Style.panel.text
            font.pointSize: 9
            color: parent.containsMouse? Style.panel.text.darkColor : Style.panel.text.color

            text: element
          }
        }
      }
    }
  }

  Component {
    id: _searchResults

    Column {
      x: -10

      Repeater {
        model: SearchModel

        SearchResult {
          width: root.width - 20

          kind: objKind
          cover: objCover
          name: objName
          comment: objComment
          artist: objArtist

          onPlay: {
            SearchHistory.savePromit(root.text)
            AudioPlayer.playYmTrack(objId)
            _root.focus = true
          }
        }
      }
    }
  }
}
