import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "../components"
import ".."

MouseArea {
  id: root

  height: 56
  
  property string title: ""
  property string comment: ""
  property string author: ""
  property url cover
  property bool liked: false
  property string duration: "0:00"
  property int idInt

  property bool playing: false

  property bool sellectedIn: playing || containsMouse

  signal toggleLiked()
  signal play()
  
  hoverEnabled: true

  Rectangle {
    id: _background
    anchors.fill: parent
    radius: 7.5
    color: sellectedIn? Style.window.sellection.background : "transparent"
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.play()
  }

  Image {
    id: _cover
    visible: false
    width: 40
    height: 40
    sourceSize: Qt.size(width, height)
    anchors.verticalCenter: parent.verticalCenter
    x: 10

    source: root.cover
    fillMode: Image.PreserveAspectCrop
  }

  RoundMask {
    id: _roundCover
    anchors.fill: _cover
    radius: 7.5

    source: _cover
  }

  DText {
    id: _title
    anchors.bottom: parent.verticalCenter
    anchors.bottomMargin: 2
    anchors.left: _cover.right
    anchors.leftMargin: 10

    text: root.title
    font.pointSize: 10.5
    color: Style.window.text.color
  }

  DText {
    id: _comment
    anchors.bottom: parent.verticalCenter
    anchors.bottomMargin: 2
    anchors.left: _title.right
    anchors.leftMargin: 5

    text: root.comment
    font.pointSize: 10.5
    color: Style.darkTheme? "#999999" : "#999999"
  }

  DText {
    id: _author
    anchors.top: parent.verticalCenter
    anchors.topMargin: 2
    anchors.left: _cover.right
    anchors.leftMargin: 10

    text: root.author
    font.pointSize: 9
    color: Style.darkTheme? "#CCCCCC" : "#515151"
  }

  DText {
    id: _duration
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: 20

    text: root.duration
    font.pointSize: 10.5
    color: Style.darkTheme? "#CCCCCC" : "#515151"
  }

  PlayerControlsButton {
    id: _like
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.right
    anchors.rightMargin: 85
    width: 16
    height: 14

    icon: root.liked? "qrc:/resources/playlist/liked.svg" : "qrc:/resources/playlist/like.svg"

    onClick: root.toggleLiked()
  }
}
