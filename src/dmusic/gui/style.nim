import uibase

type
  ButtonStyle* = object
    color*: Col
    hoverColor*: Col
    pressedColor*: Col
    unavailableColor*: Col
    backgroundColor*: Col
    hoverBackgroundColor*: Col
    pressedBackgroundColor*: Col

  Style* = ref object
    color*: Col
    color2*: Col
    color3*: Col
    backgroundColor*: Col
    button*, accentButton*: ButtonStyle
    borders*: bool
    borderColor*: Col
    
    accent*: Col
    itemBackground*: Col
    itemColor*: Col
    itemDropShadow*: bool

    typeface*: Typeface
  
  FullStyle* = object
    window*, header*, panel*: Style
  
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
