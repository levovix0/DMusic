import QtQuick 2.15

Item {
  id: root

  property Item target
  property bool opened: false
  property bool running: _trans.running
  property real shift: maxShift
  property real maxShift: 20
  property real duration: 0.25

  Binding { target: root.target; property: "visible"; value: root.opened || root.running }

  states: [
    State {
      name: "closed"; when: !root.opened
      PropertyChanges { target: root.target; opacity: 0 }
      PropertyChanges { target: root; shift: maxShift; }
    },
    State {
      name: "opened"; when: root.opened
      PropertyChanges { target: root.target; opacity: 1 }
      PropertyChanges { target: root; shift: 0; }
    }
  ]

  transitions: Transition {
    id: _trans
    NumberAnimation { properties: "shift, opacity"; duration: root.duration * 1000; easing.type: Easing.OutCubic }
  }
}
