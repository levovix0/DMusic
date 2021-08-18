import QtQuick 2.15
import DMusic 1.0
import "../../components"

Rectangle {
  id: root
  width: 45
  height: 45

  property color dark
  property color light
  property bool selected: Config.colorAccentDark == dark && Config.colorAccentLight == light

  radius: 7.5

  color: Config.darkTheme? dark : light

  MouseArea {
    anchors.fill: parent
    visible: !root.selected
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      Config.colorAccentDark = root.dark
      Config.colorAccentLight = root.light
    }
  }

  Icon {
    anchors.centerIn: parent
    visible: root.selected
    color: Config.darkTheme? Style.panel.background : "#FFFFFF"
    src: "qrc:/resources/settings/selected.svg"
  }
}
