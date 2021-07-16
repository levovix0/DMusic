import QtQuick 2.15
import QtQuick.Controls 2.15
//TODO: Не работает

Control {
  id: root
  padding: 5
  property alias opened: _ppc.opened

  PopupController {
    id: _ppc
    target: root.contentItem
  }

  property bool autoClose: false

  background: MouseArea {
    id: _bg_mouse
    visible: autoClose && (_ppc.opened || _ppc.running)
    width: root.leftPadding + root.implicitContentWidth + root.rightPadding
    height: root.topPadding + root.implicitContentHeight + root.bottomPadding

    onExited: _ppc.opened = false

    hoverEnabled: true
  }

  Binding { target: contentItem; property: "x"; value: _ppc.shift }
  Binding { target: contentItem; property: "visible"; value: _ppc.opened || _ppc.running }
}
