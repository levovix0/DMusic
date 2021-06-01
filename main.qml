import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import DMusic 1.0

Window {
  id: _root
  visible: true
  Component.onCompleted: {
    if (manualTitle) {
      flags += Qt.FramelessWindowHint
    }
  }

  width: 1280
  height: 720
  minimumWidth: 1040
  minimumHeight: 600

  property bool manualTitle: _settings.isClientSideDecorations

  title: "DMusic"

  function maximize() {
    visibility = visibility == 2 ? 4 : 2
  }
  function minimize() {
    _root.showMinimized()
  }
  color: manualTitle? "transparent" : "#181818"

  Rectangle {
    id: root
    width: _root.width
    height: _root.height

    color: "#181818"
    focus: true

    MouseArea {
      anchors.fill: parent
      onClicked: root.focus = true
    }

    Settings {
      id: _settings

      Component.onCompleted: {
        YClient.init()
        root.autologin()
      }
    }

    function afterLogin() {
      _userDailyPlaylist.playlist = YClient.userDailyPlaylist()
      _userLikedPlaylist.playlist = YClient.userLikedTracks()
    }

    function autologin() {
      if (_settings.ym_token == "") return
      if (_settings.ym_proxyServer == "") {
        YClient.login(_settings.ym_token, afterLogin)
      } else {
        YClient.loginViaProxy(_settings.ym_token, _settings.ym_proxyServer, afterLogin)
      }
    }

    Player {
      id: _player
      width: root.width
      height: 66
      anchors.bottom: parent.bottom

      settings: _settings
    }

    Title {
      id: _title
      width: root.width

      window: _root
      manual: _root.manualTitle
    }

    DTextBox {
      id: _id_input
      anchors.centerIn: root
      width: root.width / 3 * 2

      hint: qsTr("ID")
    }

    Item {
      anchors.top: root.verticalCenter
      anchors.horizontalCenter: root.horizontalCenter
      anchors.topMargin: 20
      height: Math.max(_play_playlist.height, _play.height, _play_downloads.height)
      width: _play_playlist.width + 10 + _play.width + 10 + _play_downloads.width + 10 + _play_user.width

      DButton {
        id: _play_playlist

        text: qsTr("Play playlist")

        onClick: {
          if (_id_input.text == "") return
          _player.player.play(YClient.playlist(parseInt(_id_input.text)))
        }
      }

      DButton {
        id: _play
        anchors.left: _play_playlist.right
        anchors.leftMargin: 10

        //: Play button
        text: qsTr("Play")

        onClick: {
          if (_id_input.text == "") return
          _player.player.play(YClient.oneTrack(parseInt(_id_input.text)))
        }
      }

      DButton {
        id: _play_downloads
        anchors.left: _play.right
        anchors.leftMargin: 10

        text: qsTr("Play downloaded")

        onClick: {
          _player.player.play(YClient.downloadsPlaylist())
        }
      }

      DButton {
        id: _play_user
        anchors.left: _play_downloads.right
        anchors.leftMargin: 10

        text: qsTr("Play custom")

        onClick: {
          _player.player.play(YClient.userTrack(parseInt(_id_input.text)))
        }
      }
    }

    DTextBox {
      id: _tb_title
      anchors.centerIn: root
      anchors.verticalCenterOffset: 80
      width: root.width / 3

      hint: qsTr("Title")
    }

    DTextBox {
      id: _tb_artists
      anchors.horizontalCenter: _tb_title.horizontalCenter
      anchors.top: _tb_title.bottom
      anchors.topMargin: 10
      width: root.width / 3

      hint: qsTr("Artists")
    }

    DTextBox {
      id: _tb_extra
      anchors.horizontalCenter: _tb_artists.horizontalCenter
      anchors.top: _tb_artists.bottom
      anchors.topMargin: 10
      width: root.width / 3

      hint: qsTr("Extra")
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
      onAccepted: YClient.addUserTrack(_openMedia.media, fileUrl.toString(), _tb_title.text, _tb_artists.text, _tb_extra.text)
      onRejected: YClient.addUserTrack(_openMedia.media, "", _tb_title.text, _tb_artists.text, _tb_extra.text)
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
            YClient.addUserTrack(media, "", _tb_title.text, _tb_artists.text, _tb_extra.text)
          } else {
            YClient.addUserTrack(media, cover, _tb_title.text, _tb_artists.text, _tb_extra.text)
          }
        }
      }
    }

    DButton {
      id: _addUserTrack
      anchors.horizontalCenter: _tb_extra.horizontalCenter
      anchors.top: _tb_extra.bottom
      anchors.topMargin: 10

      text: qsTr("Add custom track")

      onClick: {
        _openFile.show()
      }
    }

    Keys.onSpacePressed: _player.player.pause_or_play()
    Keys.onRightPressed: _player.next()
    Keys.onLeftPressed: _player.prev()
    Keys.onPressed: {
      if (event.key == Qt.Key_L) _player.toglleLiked()
      else if (event.key == Qt.Key_D) _player.next()
      else if (event.key == Qt.Key_A) _player.prev()
    }

    PlaylistEntry {
      id: _userLikedPlaylist
      anchors.left: root.left
      anchors.top: _title.bottom
      anchors.leftMargin: 25
      anchors.topMargin: 25

      onPlay: YClient.playPlaylist(playlist)
    }

    PlaylistEntry {
      id: _userDailyPlaylist
      anchors.left: _userLikedPlaylist.right
      anchors.top: _title.bottom
      anchors.leftMargin: 25
      anchors.topMargin: 25

      onPlay: YClient.playPlaylist(playlist)
    }

    ListModel {
      id: _messages
    }

    Column {
      spacing: 15
      anchors.bottom: _player.top
      anchors.bottomMargin: 15
      anchors.horizontalCenter: parent.horizontalCenter

      add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
      }

      Repeater {
        model: _messages
        Message {
          text: elementText
          details: elementDetails
          isError: elementIsError
          anchors.horizontalCenter: parent.horizontalCenter

          onClosed: _messages.remove(index)
        }
      }
    }

    Component.onCompleted: {
      Messages.onGotMessage.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": false })
      })
      Messages.onGotError.connect(function(text, details) {
        _messages.append({ "elementText": text, "elementDetails": details, "elementIsError": true })
      })
      Messages.reSendHistory()
    }

    layer.enabled: manualTitle && visibility != 4
    layer.effect: OpacityMask {
      maskSource: Item {
        width: root.width
        height: root.height
        Rectangle {
          anchors.fill: parent
          radius: 7.5
        }
      }
    }
  }
}
