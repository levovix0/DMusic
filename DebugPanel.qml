import QtQuick 2.0
import QtQuick.Dialogs 1.2
import DMusic 1.0
import "external"

FloatingPanel {
  id: root

  width: 320
  height: 122

  property Player player

  DTextBox {
    id: _id
    width: 155
    height: 20
    color: "#181818"
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
    color: "#181818"
    anchors.left: _cover.right
    anchors.top: _cover.top
    anchors.leftMargin: 10
    hint: qsTr("Title")
  }

  DTextBox {
    id: _extra
    width: 115
    height: 20
    color: "#181818"
    anchors.left: _title.right
    anchors.top: _title.top
    anchors.leftMargin: 10
    hint: qsTr("Additional info")
  }

  DTextBox {
    id: _artists
    x: 82
    width: 169
    height: 20
    color: "#181818"
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
    filter: qsTr("Audio (*.mp3 *.wav *.ogg *.m4a)")

    Icon {
      anchors.centerIn: parent
      src: "qrc:/resources/debug/drop-media.svg"
      color: parent.hasContent? "#78c0ff" : Style.dropPlace.border.color
    }
  }

  IconButton {
    id: _track
    width: 20
    height: 20
    anchors.left: _id.right
    anchors.top: _id.top
    src: "resources/debug/track.svg"
    anchors.leftMargin: 12

    onClicked: {
      if (_id.text === "") return
      try {
        player.player.play(YClient.oneTrack(parseInt(_id.text)))
      } catch (e) {}
    }
  }

  IconButton {
    id: _playlist
    width: 20
    height: 20
    anchors.left: _track.right
    anchors.top: _id.top
    anchors.leftMargin: 12
    src: "resources/debug/playlist.svg"

    onClicked: {
      if (_id.text === "") return
      try {
        player.player.play(YClient.playlist(parseInt(_id.text)))
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
    src: "resources/debug/downloads.svg"

    onClicked: {
      try {
        player.player.play(YClient.downloadsPlaylist())
      } catch (e) {}
    }
  }

  IconButton {
    id: _user
    width: 20
    height: 20
    anchors.left: _downloads.right
    anchors.top: _id.top
    anchors.leftMargin: 12
    src: "resources/debug/user.svg"

    onClicked: {
      if (_id.text === "") return
      try {
        player.player.play(YClient.userTrack(parseInt(_id.text)))
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
    src: "resources/debug/add.svg"

    onClicked: {
      if (!_media.hasContent) return
      if (!_cover.hasContent) {
        YClient.addUserTrack(_media.content.toString(), "", _title.text, _artists.text, _extra.text)
      } else {
        YClient.addUserTrack(_media.content.toString(), _cover.content.toString(), _title.text, _artists.text, _extra.text)
      }
    }
  }
}
