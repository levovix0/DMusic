import QtQuick 2.0
import QtQuick.Dialogs 1.2
import DMusic 1.0
import "components"

FloatingPanel {
  id: root

  width: 320
  height: 122

  property var player

  DTextBox {
    id: _id
    width: 185
    height: 20
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 20
    anchors.topMargin: 20
    hint: qsTr("ID")
  }

  DropPlace {
    id: _cover
    width: 50
    height: 50
    anchors.left: _id.left
    anchors.top: _id.bottom
    anchors.topMargin: 10
    filter: qsTr("Image (*.jpg *.png *.svg)")
    dropFilter: "(*)"

    Icon {
      anchors.centerIn: parent
      visible: !parent.hasContent

      src: "qrc:/resources/debug/drop-cover.svg"
      color: Style.dropPlace.border.color
    }

    RoundedImage {
      anchors.fill: parent
      anchors.margins: 1
      sourceSize: Qt.size(width, height)
      visible: parent.hasContent

      radius: Style.dropPlace.border.radius
      source: parent.content
      fillMode: Image.PreserveAspectCrop
      clip: true
    }
  }

  DTextBox {
    id: _title
    width: 100
    anchors.left: _cover.right
    anchors.top: _cover.top
    anchors.leftMargin: 10
    hint: qsTr("Title")
  }

  DTextBox {
    id: _comment
    width: 115
    height: 20
    anchors.left: _title.right
    anchors.top: _title.top
    anchors.leftMargin: 10
    hint: qsTr("Comment")
  }

  DTextBox {
    id: _artists
    x: 82
    width: 169
    height: 20
    anchors.top: _title.bottom
    anchors.topMargin: 10
    hint: qsTr("Artists")
  }

  DropPlace {
    id: _media
    width: 20
    height: 20
    antialiasing: true
    anchors.left: _artists.right
    anchors.top: _artists.top
    anchors.leftMargin: 10
    filter: qsTr("MP3 (*.mp3)")

    Icon {
      anchors.centerIn: parent
      src: "qrc:/resources/debug/drop-media.svg"
      color: parent.hasContent? Style.accent : Style.dropPlace.border.color
    }
  }

  IconButton {
    id: _playlist
    width: 20
    height: 20
    anchors.left: _id.right
    anchors.top: _id.top
    anchors.leftMargin: 12
    src: "qrc:/resources/debug/playlist.svg"

    onClicked: {
      if (_id.text === "") return
      try {
        AudioPlayer.playYmUserPlaylist(parseInt(_id.text))
      } catch (e) {}
    }
  }

  IconButton {
    id: _downloads
    width: 20
    height: 20
    anchors.left: _playlist.right
    anchors.top: _id.top
    anchors.leftMargin: 12
    src: "qrc:/resources/debug/downloads.svg"

    onClicked: AudioPlayer.playDownloads()
  }

  IconButton {
    id: _user
    width: 20
    height: 20
    anchors.left: _downloads.right
    anchors.top: _id.top
    anchors.leftMargin: 12
    src: "qrc:/resources/debug/user.svg"

    onClicked: {
      if (_id.text === "") return
      try {
        AudioPlayer.playUserTrack(parseInt(_id.text))
      } catch (e) {}
    }
  }

  IconButton {
    id: _add
    width: 20
    height: 20
    anchors.left: _media.right
    anchors.top: _media.top
    anchors.leftMargin: 6
    src: "qrc:/resources/debug/add.svg"

    onClicked: {
      if (!_media.hasContent) return
      if (!_cover.hasContent) {
        AudioPlayer.addUserTrack(_media.content.toString(), "", _title.text, _comment.text, _artists.text)
      } else {
        AudioPlayer.addUserTrack(_media.content.toString(), _cover.content.toString(), _title.text, _comment.text, _artists.text)
      }
    }
  }
}
