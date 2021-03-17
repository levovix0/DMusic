import QtQuick 2.0

Item {
  id: root
  property alias color: _icon.color

  Icon {
    height: 8
    id: _icon
    anchors.horizontalCenter: root.horizontalCenter
    anchors.top: root.top

    src: "qrc:/resources/tri.svg"
  }
}
