import QtQuick 2.0

Item {
  id: root

  width: 25
  height: 25

  property string icon: ""
  property alias image: _icon.image
  property string color: "#C1C1C1"
  property string hoverColor: "#FFFFFF"

  signal click()

  Icon {
    id: _icon
    anchors.centerIn: root

    src: icon
    color: _mouse.containsMouse? root.hoverColor : root.color
  }

  MouseArea {
    id: _mouse
    anchors.fill: root

    hoverEnabled: true

    onClicked: root.click()
  }
}
