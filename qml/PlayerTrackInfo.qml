import QtQuick 2.15
import DMusic 1.0
import "components"

Item {
  id: root

  property string title: ""
  property string artists: ""
  property string comment: ""
  property int trackId
  property bool liked: false
  property bool isYandex: false

  signal toggleLiked(bool liked)

  Item {
    anchors.fill: root

    clip: true

    DText {
      id: _title
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2

      text: title
      font.pointSize: 10.5
      color: Style.panel.text.color

      MouseArea {
        anchors.fill: parent
        enabled: root.isYandex

        cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        Clipboard {
          id: _clipboard
        }

        onClicked: _clipboard.copy(root.trackId);

        onEntered: _full_titleAndComment.show()
        onExited: _full_titleAndComment.hide()
      }
    }

    DText {
      id: _comment
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2
      anchors.left: _title.right
      anchors.leftMargin: 5

      text: comment
      font.pointSize: 10.5
      color: Style.darkHeader? "#999999" : "#999999"

      MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        onEntered: _full_titleAndComment.show()
        onExited: _full_titleAndComment.hide()
      }
    }

    DText {
      id: _artists
      anchors.top: parent.verticalCenter
      anchors.topMargin: 2

      text: artists
      font.pointSize: 9
      color: Style.darkHeader? "#CCCCCC" : "#515151"

      MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        onEntered: _full_artists_box.show()
        onExited: _full_artists_box.hide()
      }
    }

    Rectangle {
      id: _shade_titleAndExtra
      width: 10
      height: Math.max(_title.height, _comment.height)
      anchors.right: parent.right
      anchors.verticalCenter: _title.verticalCenter

      OpacityAnimator {
        target: _shade_titleAndExtra
        id: _anim_shade_titleAndComment_opacity
        duration: 300
        easing.type: Easing.OutCubic
      }

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Style.panel.background }
      }
    }

    Rectangle {
      id: _shade_artists
      width: 10
      height: _artists.height
      anchors.right: parent.right
      anchors.verticalCenter: _artists.verticalCenter

      OpacityAnimator {
        target: _shade_artists
        id: _anim_shade_artists_opacity
        duration: 300
        easing.type: Easing.OutCubic
      }

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Style.panel.background }
      }
    }
  }

  PlayerControlsButton {
    id: _like
    anchors.bottom: parent.verticalCenter
    x: Math.round(Math.min(_title.width + (_comment.text == ""? 0 : _comment.width + 2) + 5, root.width + 2))
    anchors.bottomMargin: -1
    visible: root.isYandex

    icon: liked? "qrc:/resources/player/liked.svg" : "qrc:/resources/player/like.svg"

    onClick: toggleLiked(!liked)
  }

  Rectangle {
    id: _full_titleAndComment
    height: Math.max(_full_title.height, _full_extra.height) + 6
    width: _full_title.width + 5 + _full_extra.width + 5 - root.width
    anchors.bottom: parent.verticalCenter
    anchors.bottomMargin: -1
    x: root.width

    property bool showing: false

    clip: true
    opacity: 0
    color: Style.panel.background

    OpacityAnimator {
      target: _full_titleAndComment
      id: _anim_full_titleAndComment_opacity
      duration: 300
      easing.type: Easing.OutCubic
    }

    function show() {
      if (showing) return
      showing = true
      _anim_full_titleAndComment_opacity.from = 0
      _anim_full_titleAndComment_opacity.to = 1
      _anim_full_titleAndComment_opacity.restart()
      _anim_shade_titleAndComment_opacity.from = 1
      _anim_shade_titleAndComment_opacity.to = 0
      _anim_shade_titleAndComment_opacity.restart()
    }
    function hide() {
      if (!showing) return
      showing = false
      _anim_full_titleAndComment_opacity.from = 1
      _anim_full_titleAndComment_opacity.to = 0
      _anim_full_titleAndComment_opacity.restart()
      _anim_shade_titleAndComment_opacity.from = 0
      _anim_shade_titleAndComment_opacity.to = 1
      _anim_shade_titleAndComment_opacity.restart()
    }

    DText {
      id: _full_title
      anchors.verticalCenter: parent.verticalCenter
      x: -root.width

      text: title
      font.pointSize: 10.5
      color: Style.panel.text.color
    }

    DText {
      id: _full_extra
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: _full_title.right
      anchors.leftMargin: 5

      text: comment
      font.pointSize: 10.5
      color: Style.darkHeader? "#999999" : "#999999"
    }
  }


  Rectangle {
    id: _full_artists_box
    height: Math.max(_full_title.height, _full_extra.height) + 3
    width: _full_artists.width + 5 - root.width
    anchors.top: parent.verticalCenter
    anchors.topMargin: 2
    x: root.width

    property bool showing: false

    clip: true
    opacity: 0
    color: Style.panel.background

    OpacityAnimator {
      target: _full_artists_box
      id: _anim_full_artists_opacity
      duration: 300
      easing.type: Easing.OutCubic
    }

    function show() {
      if (showing) return
      showing = true
      _anim_full_artists_opacity.from = 0
      _anim_full_artists_opacity.to = 1
      _anim_full_artists_opacity.restart()
      _anim_shade_artists_opacity.from = 1
      _anim_shade_artists_opacity.to = 0
      _anim_shade_artists_opacity.restart()
    }
    function hide() {
      if (!showing) return
      showing = false
      _anim_full_artists_opacity.from = 1
      _anim_full_artists_opacity.to = 0
      _anim_full_artists_opacity.restart()
      _anim_shade_artists_opacity.from = 0
      _anim_shade_artists_opacity.to = 1
      _anim_shade_artists_opacity.restart()
    }

    DText {
      id: _full_artists
      anchors.top: parent.top
      x: -root.width

      text: artists
      font.pointSize: 9
      color: Style.darkHeader? "#CCCCCC" : "#515151"
    }
  }
}
