import uibase

type
  Style* = ref object
    color*: Col
    backgroundColor*: Col
    buttonBackgroundColor*: Col
    hoverButtonBackgroundColor*: Col
  
  FullStyle* = object
    window*, header*: Style
  
  StyleChanged* = ref object of SubtreeSignal
    fullStyle*: FullStyle
    style*: Style


template withStyleForChilds*(signal: StyleChanged, s: untyped, body: untyped) =
  let prevStyle = signal.style
  signal.style = signal.fullStyle.s
  try:
    body
  finally:
    signal.style = prevStyle