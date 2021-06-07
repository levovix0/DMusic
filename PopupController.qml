import QtQuick 2.15

Item {
  id: root

  property Item target
  property bool opened: false
  property bool animationEnded: true
  property real shift: 0
  property real maxShift: 20
  property real duration: 0.25

  OpacityAnimator {
    target: root.target
    id: _anim_opacity
    duration: root.duration * 1000
    easing.type: Easing.OutCubic
  }

  NumberAnimation on shift {
    id: _anim_pos
    duration: root.duration * 1000
    easing.type: Easing.OutCubic
  }

  function fullShow() {
    target.opacity = 1
    animationEnded = true
    _anim_opacity.finished.disconnect(fullShow)
  }
  function fullHide() {
    target.opacity = 0
    animationEnded = true
    _anim_opacity.finished.disconnect(fullHide)
  }

  onOpenedChanged: {
    animationEnded = false
    if (opened) {
      _anim_opacity.from = 0
      _anim_opacity.to = 1

      _anim_pos.from = maxShift
      _anim_pos.to = 0

      _anim_opacity.finished.disconnect(fullHide)
      _anim_opacity.finished.disconnect(fullShow)

      _anim_opacity.stop()
      _anim_pos.stop()

      _anim_opacity.finished.connect(fullShow)

      _anim_opacity.restart()
      _anim_pos.restart()
    } else {
      _anim_opacity.from = 1
      _anim_opacity.to = 0

      _anim_pos.from = 0
      _anim_pos.to = maxShift

      _anim_opacity.finished.disconnect(fullHide)
      _anim_opacity.finished.disconnect(fullShow)

      _anim_opacity.stop()
      _anim_pos.stop()

      _anim_opacity.finished.connect(fullHide)

      _anim_opacity.start()
      _anim_pos.start()
    }
  }
}
