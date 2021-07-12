import QtQuick 2.15
import DMusic 1.0

Item {
  id: root

  property string title: ""
  property string artists: ""
  property string extra: ""
  property string idStr: ""
  property bool liked: false

  signal toggleLiked(bool liked)

  Item {
    anchors.fill: root

    clip: true

    DText {
      id: _title
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2

      text: title
      font.pixelSize: 14

      MouseArea {
        anchors.fill: parent
        enabled: root.idStr != ""

        cursorShape: enabled? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true

        Clipboard {
          id: _clipboard
        }

        onClicked: _clipboard.copy(root.idStr);

        onEntered: _full_titleAndExtra.show()
        onExited: _full_titleAndExtra.hide()
      }
    }

    DText {
      id: _extra
      anchors.bottom: parent.verticalCenter
      anchors.bottomMargin: 2
      anchors.left: _title.right
      anchors.leftMargin: 5

      text: extra
      font.pixelSize: 14
      color: "#999999"

      MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        onEntered: _full_titleAndExtra.show()
        onExited: _full_titleAndExtra.hide()
      }
    }

    DText {
      id: _artists
      anchors.top: parent.verticalCenter
      anchors.topMargin: 2

      text: artists
      font.pixelSize: 12
      color: "#CCCCCC"

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
      height: Math.max(_title.height, _extra.height)
      anchors.right: parent.right
      anchors.verticalCenter: _title.verticalCenter

      OpacityAnimator {
        target: _shade_titleAndExtra
        id: _anim_shade_titleAndExtra_opacity
        duration: 300
        easing.type: Easing.OutCubic
      }

      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: "#262626" }
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
        GradientStop { position: 1.0; color: "#262626" }
      }
    }
  }

  PlayerControlsButton {
    id: _like
    anchors.bottom: parent.verticalCenter
    x: Math.round(Math.min(_title.width + (_extra.text == ""? 0 : _extra.width + 2) + 5, root.width + 2))
    anchors.bottomMargin: -1
    visible: idStr != ""

    icon: liked? "qrc:/resources/player/liked.svg" : "qrc:/resources/player/like.svg"

    onClick: toggleLiked(!liked)
  }

  Rectangle {
    id: _full_titleAndExtra
    height: Math.max(_full_title.height, _full_extra.height) + 6
    width: _full_title.width + 5 + _full_extra.width + 5 - root.width
    anchors.bottom: parent.verticalCenter
    anchors.bottomMargin: -1
    x: root.width

    property bool showing: false

    clip: true
    opacity: 0
    color: "#262626"

    OpacityAnimator {
      target: _full_titleAndExtra
      id: _anim_full_titleAndExtra_opacity
      duration: 300
      easing.type: Easing.OutCubic
    }

    function show() {
      if (showing) return
      showing = true
      _anim_full_titleAndExtra_opacity.from = 0
      _anim_full_titleAndExtra_opacity.to = 1
      _anim_full_titleAndExtra_opacity.restart()
      _anim_shade_titleAndExtra_opacity.from = 1
      _anim_shade_titleAndExtra_opacity.to = 0
      _anim_shade_titleAndExtra_opacity.restart()
    }
    function hide() {
      if (!showing) return
      showing = false
      _anim_full_titleAndExtra_opacity.from = 1
      _anim_full_titleAndExtra_opacity.to = 0
      _anim_full_titleAndExtra_opacity.restart()
      _anim_shade_titleAndExtra_opacity.from = 0
      _anim_shade_titleAndExtra_opacity.to = 1
      _anim_shade_titleAndExtra_opacity.restart()
    }

    DText {
      id: _full_title
      anchors.verticalCenter: parent.verticalCenter
      x: -root.width

      text: title
      font.pixelSize: 14
    }

    DText {
      id: _full_extra
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: _full_title.right
      anchors.leftMargin: 5

      text: extra
      font.pixelSize: 14
      color: "#999999"
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
    color: "#262626"

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
      font.pixelSize: 12
      color: "#CCCCCC"
    }
  }
}
