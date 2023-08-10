import uibase

type
  ButtonStyle* = object
    color*: Col
    hoverColor*: Col
    pressedColor*: Col
    backgroundColor*: Col
    hoverBackgroundColor*: Col
    pressedBackgroundColor*: Col

  Style* = ref object
    color*: Col
    backgroundColor*: Col
    button*, accentButton*: ButtonStyle
    borders*: bool
    borderColor*: Col
  
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
