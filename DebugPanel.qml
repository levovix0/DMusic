import QtQuick 2.0
import QtQuick.Dialogs 1.2
import DMusic 1.0

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

  Rectangle {
    id: _cover
    width: 50
    height: 50
    color: "#ffffff"
    anchors.left: _id.left
    anchors.top: _id.bottom
    anchors.topMargin: 10
    anchors.leftMargin: 0
  }

  DTextBox {
    id: _title
    width: 99
    color: "#181818"
    anchors.left: _cover.right
    anchors.top: _cover.top
    anchors.topMargin: 0
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
    anchors.topMargin: 0
    hint: qsTr("Additional info")
  }

  DTextBox {
    id: _artists
    x: 82
    width: 137
    height: 20
    color: "#181818"
    anchors.top: _title.bottom
    anchors.topMargin: 10
    hint: qsTr("Artists")
  }

  Rectangle {
    id: _file
    width: 49
    height: 20
    color: "#ffffff"
    anchors.left: _artists.right
    anchors.top: _artists.top
    anchors.leftMargin: 10
    anchors.topMargin: 0
  }

  IconButton {
    id: _track
    width: 20
    height: 20
    anchors.left: _id.right
    anchors.top: _id.top
    src: "resources/debug/track.svg"
    anchors.leftMargin: 12
    anchors.topMargin: 0

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
    anchors.topMargin: 0
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
    anchors.topMargin: 0
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
    anchors.topMargin: 0
    src: "resources/debug/user.svg"

    onClicked: {
      if (_id.text === "") return
      try {
        player.player.play(YClient.userTrack(parseInt(_id.text)))
      } catch (e) {}
    }
  }

  FileDialog {
    id: _openMedia
    title: qsTr("Chose media")
    nameFilters: [qsTr("Audio (*.mp3 *.wav *.ogg *.m4a)")]
    property string media: ""
    onAccepted: {
      media = fileUrl.toString()
      _openCover.open()
    }
  }

  FileDialog {
    id: _openCover
    title: qsTr("Chose cover")
    nameFilters: [qsTr("Image (*.jpg *.png *.svg)")]
    onAccepted: YClient.addUserTrack(_openMedia.media, fileUrl.toString(), _title.text, _artists.text, _extra.text)
    onRejected: YClient.addUserTrack(_openMedia.media, "", _title.text, _artists.text, _extra.text)
  }

  DFileDialog {
    id: _openFile
    function show() {
      if (!available()) _openMedia.open()
      else {
        let media = sellect(qsTr("Chose media"), "*.mp3 *.wav *.ogg *.m4a", qsTr("Audio (*.mp3 *.wav *.ogg *.m4a)"))
        if (media === "") return
        let cover = sellect(qsTr("Chose cover"), "*.jpg *.png *.svg", qsTr("Image (*.jpg *.png *.svg)"))
        if (cover === "") {
          YClient.addUserTrack(media, "", _title.text, _artists.text, _extra.text)
        } else {
          YClient.addUserTrack(media, cover, _title.text, _artists.text, _extra.text)
        }
      }
    }
  }

  IconButton {
    id: _add
    width: 20
    height: 20
    anchors.left: _file.right
    anchors.top: _file.top
    anchors.leftMargin: 6
    anchors.topMargin: 0
    src: "resources/debug/add.svg"

    onClicked: _openFile.show()
  }
}
