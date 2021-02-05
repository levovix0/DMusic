import QtQuick 2.0

Rectangle {
  id: root

  color: "#262626"

  PlayerControls {
    anchors.horizontalCenter: root.horizontalCenter
    y: 21
  }

  PlayerLine {
    anchors.horizontalCenter: root.horizontalCenter
    y: 48
    width: root.width / 2.7
  }

  PlayerTrack {
    x: 8
    anchors.verticalCenter: root.verticalCenter
//    icon: "https://avatars.yandex.net/get-music-user-playlist/70586/809996147.1020.7755/m1000x1000?1606739484624"
    icon: "https://media.discordapp.net/attachments/591064670677237826/805101727128354816/art.png?width=627&height=627"
    name: "Nothing"
    author: "LightFly"
    additional: "Original Mix"
  }
}
