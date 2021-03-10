import QtQuick 2.0

Rectangle {
  id: root

  property string icon: ""
  property string hoverColor: "#303030"
  signal click()
  signal pressed()

  enabled: true
  visible: enabled
  width: enabled? 50 : 0
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

    onClicked: if (enabled) root.click()
    onPressed: if (enabled) root.pressed()
  }
}
