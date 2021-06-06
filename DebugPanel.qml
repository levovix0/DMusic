import QtQuick 2.0

FloatingPanel {
  id: root

  width: 320
  height: 122

  DTextBox {
      id: dTextBox
      width: 155
      height: 20
      color: "#181818"
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: 20
      anchors.topMargin: 20
      hint: "ID"
  }

  Rectangle {
      id: rectangle
      width: 52
      height: 52
      color: "#ffffff"
      anchors.left: parent.left
      anchors.top: dTextBox.bottom
      anchors.topMargin: 10
      anchors.leftMargin: 20
  }

  DTextBox {
      id: dTextBox1
      width: 99
      color: "#181818"
      anchors.left: rectangle.right
      anchors.top: rectangle.top
      anchors.topMargin: 0
      anchors.leftMargin: 10
      hint: "Заголовок"
  }

  DTextBox {
      id: dTextBox2
      width: 115
      height: 20
      color: "#181818"
      anchors.left: dTextBox1.right
      anchors.top: rectangle.top
      anchors.leftMargin: 6
      anchors.topMargin: 0
      hint: "Доп. Инфо"
  }

  DTextBox {
      id: dTextBox3
      x: 82
      width: 137
      height: 20
      color: "#181818"
      anchors.top: dTextBox1.bottom
      anchors.topMargin: 12
      hint: "Авторы"
  }

  Rectangle {
      id: rectangle1
      x: 231
      width: 49
      height: 20
      color: "#ffffff"
      anchors.top: dTextBox3.top
      anchors.topMargin: 0
  }

  Icon {
    id: track
    width: 20
    height: 20
    anchors.left: dTextBox.right
    anchors.top: dTextBox.top
    image.source: "resources/debug/track.svg"
    src: "qrc:/debug/track.svg"
    anchors.leftMargin: 12
    anchors.topMargin: 0
  }

  Icon {
    id: playlist
    width: 20
    height: 20
    anchors.left: track.right
    anchors.top: dTextBox.top
    anchors.leftMargin: 12
    anchors.topMargin: 0
    src: "resources/debug/playlist.svg"
  }

  Icon {
    id: downloads
    width: 20
    height: 20
    anchors.left: playlist.right
    anchors.top: dTextBox.top
    anchors.leftMargin: 12
    anchors.topMargin: 0
    src: "resources/debug/downloads.svg"
  }

  Icon {
    id: user
    width: 20
    height: 20
    anchors.left: downloads.right
    anchors.top: dTextBox.top
    anchors.leftMargin: 12
    anchors.topMargin: 0
    src: "resources/debug/user.svg"
  }

  Icon {
      id: user1
      width: 20
      height: 20
      anchors.left: rectangle1.right
      anchors.top: rectangle1.top
      anchors.leftMargin: 6
      anchors.topMargin: 0
      src: "resources/debug/add.svg"
  }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:1.75}D{i:1}D{i:2}D{i:3}D{i:4}D{i:5}D{i:6}D{i:7}D{i:8}D{i:9}D{i:10}
D{i:11}
}
##^##*/
