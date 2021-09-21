import QtQuick 2.15
import DMusic 1.0

Item {
  id: root
  width: Math.max(_icon.width, _text.width, _text2.width)
  height: childrenRect.height

  property string text: qsTr("There must be page")
  property string text2: qsTr("but there isn't")
  property url icon

  Icon {
    id: _icon
    width: 64
    height: 64
    anchors.horizontalCenter: parent.horizontalCenter

    src: root.icon
    color: Style.window.text.color
  }

  DText {
    id: _text
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: _icon.bottom
    anchors.topMargin: 24

    text: root.text
    font.pointSize: 13.5
  }

  DText {
    id: _text2
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: _text.bottom
    anchors.topMargin: 13

    text: root.text2
    font.pointSize: 8.25
    color: style.darkColor
  }
}
