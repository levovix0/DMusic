import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "components"

Rectangle {
  id: root
  height: 40

  property string kind // "track", "album", "artist"
  property url cover
  property string name
  property string comment: ""
  property string artist: ""

  property bool sellected: false

  property bool sellectedIn: sellected || _mouse.containsMouse

  signal play()

  color: sellectedIn? Style.panel.sellection.background : "transparent"
  border.width: Style.panel.sellection.border.width
  border.color: sellectedIn? Style.panel.sellection.border.color : "transparent"
  radius: 4

  MouseArea {
    id: _mouse
    anchors.fill: parent

    hoverEnabled: true

    onClicked: root.play()

    Item {
      anchors.centerIn: parent
      height: 30
      width: parent.width - 10
      clip: true

      Image {
        id: _cover
        visible: false
        width: parent.height
        height: width
        sourceSize: Qt.size(width, height)

        source: root.cover
        fillMode: Image.PreserveAspectCrop
      }

      DropShadow {
        anchors.fill: _roundCover
        radius: 4.0
        samples: 10
        transparentBorder: true
        color: "#40000000"
        source: _roundCover
      }

      RoundMask {
        id: _roundCover
        anchors.fill: _cover
        radius: root.kind == "artist"? _cover.width / 2 : 4

        source: _cover
      }

      DText {
        id: _name
        anchors.left: _roundCover.right
        anchors.leftMargin: 13
        anchors.top: artist === ""? undefined : parent.top
        anchors.verticalCenter: artist === ""? parent.verticalCenter : undefined

        font.pointSize: 9
        color: Style.panel.text.color
        text: root.name
      }

      DText {
        id: _kind
        anchors.left: _name.right
        anchors.leftMargin: 4
        anchors.verticalCenter: _name.verticalCenter

        font.pointSize: 9
        font.letterSpacing: 1
        color: Style.panel.text.commentColor
        text: root.kind == "album"? qsTr("album") : ""
      }

      DText {
        id: _comment
        anchors.left: _kind.text === ""? _name.right : _kind.right
        anchors.leftMargin: 4
        anchors.verticalCenter: _name.verticalCenter

        font.pointSize: 9
        color: Style.panel.text.commentColor
        text: root.comment
      }

      DText {
        id: _artist
        anchors.left: _roundCover.right
        anchors.leftMargin: 13
        anchors.bottom: parent.bottom

        font.pointSize: 7.5
        color: Style.panel.text.artistColor
        text: root.artist
      }
    }
  }
}
