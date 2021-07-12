import QtQuick 2.0
import DMusic 1.0
import ".."
import "../components"

DPage {
  id: root

  Icon {
    anchors.centerIn: root
    image.width: 48
    image.height: 48
    image.sourceSize: Qt.size(48, 48)
    anchors.verticalCenterOffset: -60
    src: "qrc:/resources/title/settings.svg"

    color: "#a0a0a0"
  }

  DText {
    anchors.centerIn: root
    anchors.verticalCenterOffset: 0

    color: "#a0a0a0"
    font.pixelSize: 20
    text: "Здесь должны быть настройки"
  }

  DText {
    anchors.centerIn: root
    anchors.verticalCenterOffset: 30

    color: "#909090"
    font.pixelSize: 11
    text: "Но их тут нет"
  }
}
