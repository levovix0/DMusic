import QtQuick 2.15
import QtGraphicalEffects 1.15
import DMusic 1.0
import "components"

FloatingPanel {
  id: root
  width: 250
  height: 105

  property PopupController ppc

  Item {
    anchors.fill: parent

    Column {
      Repeater {
        model: ListModel {
          ListElement {
            icon: "qrc:/resources/player/open-folder.svg"
            title: qsTr("Show in folder")
            shortcut: "Ctrl+E"
            action: function() {
              Qt.openUrlExternally(PlayingTrackInfo.folder)
            }
          }
          ListElement {
            icon: "qrc:/resources/player/open-file.svg"
            title: qsTr("Open file")
            shortcut: "Ctrl+O"
            action: function() {
              Qt.openUrlExternally(PlayingTrackInfo.file)
            }
          }
          ListElement {
            icon: "qrc:/resources/player/delete.svg"
            title: qsTr("Delete")
            shortcut: "Ctrl+Delete"
            action: function() {
              PlayingTrackInfo.remove()
            }
          }
        }
        
        delegate: Rectangle {
          height: 35
          width: root.width
          color: _mouse.containsPress? Style.panel.sellection.pressedBackground : _mouse.containsMouse? Style.panel.sellection.background : "transparent"

          MouseArea {
            id: _mouse
            anchors.fill: parent

            hoverEnabled: true
            onClicked: {
              action()
              ppc.opened = false
            }
          }

          Shortcut {
            sequence: shortcut
            onActivated: {
              action()
              ppc.opened = false
            }
          }

          Icon {
            id: _icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            width: 20
            height: 20

            color: _mouse.containsMouse? Style.panel.text.sellectedColor : Style.panel.text.unsellectedColor
            src: icon
          }

          DText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: _icon.right
            anchors.leftMargin: 10

            color: _mouse.containsMouse? Style.panel.text.sellectedColor : Style.panel.text.unsellectedColor
            text: title
          }

          DText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10

            color: Style.panel.text.darkColor
            text: shortcut
          }
        }
      }
    }

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Item {
        width: root.width
        height: root.height
        Rectangle {
          anchors.fill: parent
          radius: Style.panel.sellection.radius
        }
      }
    }
  }
}
