import QtQuick 2.0

Rectangle {
  id: root

  property string icon: ""
  property string hoverColor: "#303030"
  signal click()
  signal pressed()

  width: 50
  height: 40

  color: "transparent"

  Icon {
    anchors.centerIn: root
    src: icon
    color: "#FFFFFF"
  }

  MouseArea {
    anchors.fill: root

    hoverEnabled: true

    onEntered: root.color = root.hoverColor
    onExited: root.color = "transparent"

    onClicked: root.click()
    onPressed: root.pressed()
  }
}
