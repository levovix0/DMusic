import strutils, macros
import sigui/uibase
import ../[configuration]

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


template bindFont*(this: Uiobj, style: untyped, fontSize: float32) {.dirty.} =
  this.binding font:
    if style[] != nil and style[].typeface != nil:
      let f = newFont(style[].typeface)
      f.size = fontSize
      f
    else: nil


const robotoFont = staticRead "../../../resources/fonts/Roboto-Regular.ttf"
let typeface = parseTtf(robotoFont)

proc makeStyle*(darkTheme, darkHeader: bool): FullStyle =
  let darkHeader = darkTheme or darkHeader
  macro c(g: static string): Col =
    if g.len == 2: 
      let c = g.parseHexInt.byte
      newCall(bindSym"color", newCall(bindSym"rgbx", newLit c, newLit c, newLit c, newLit 255))
    else:
      let c = g.parseHtmlColor
      newCall(bindSym"color", newLit c.r, newLit c.g, newLit c.b, newLit c.a)

  FullStyle(
    window: Style(
      color:
        if darkTheme: c"ff"
        else: c"40",
      backgroundColor:
        if darkTheme: c"20"
        else: c"ff",
      
      button: ButtonStyle(
        color:
          if darkTheme: c"ff"
          else: c"40",
        backgroundColor:
          if darkTheme: c"30"
          else: c"f0",
      ),
      
      typeface: typeface,
    ),

    panel: Style(
      color:
        if darkHeader: c"ff"
        else: c"40",
      color2:
        if darkHeader: c"cc"
        else: c"51",
      color3: c"99",
      backgroundColor:
        if darkHeader: c"26"
        else: c"ff",
      
      accent:
        if darkHeader: config.colorAccentDark[].parseHtmlColor
        else: config.colorAccentLight[].parseHtmlColor,
      itemBackground:
        if darkHeader: c"40"
        else: c"e2",
      itemColor:
        if darkHeader: c"aa"
        else: c"80",
      itemDropShadow: not darkHeader,
      
      borders: if darkHeader: false else: true,
      borderColor: c"#D9D9D9",
      
      button: ButtonStyle(
        color:
          if darkHeader: c"c1"
          else: c"40",
        hoverColor:
          if darkHeader: c"ff"
          else: c"80",
        pressedColor:
          if darkHeader: c"a0"
          else: c"60",
        unavailableColor:
          if darkHeader: c"80"
          else: c"c1",
      ),
      
      accentButton: ButtonStyle(
        color:
          if darkHeader: config.colorAccentDark[].parseHtmlColor
          else: config.colorAccentLight[].parseHtmlColor,
        hoverColor:
          if darkHeader: config.colorAccentDark[].parseHtmlColor.lighten(0.25)
          else: config.colorAccentLight[].parseHtmlColor.darken(0.25),
        pressedColor: 
          if darkHeader: config.colorAccentDark[].parseHtmlColor.darken(0.25)
          else: config.colorAccentLight[].parseHtmlColor.lighten(0.25),
      ),
      
      typeface: typeface,
    ),

    header: Style(
      color:
        if darkHeader: c"ff"
        else: c"40",
      backgroundColor:
        if darkHeader: c"20"
        else: c"ff",
      
      button: ButtonStyle(
        color:
          if darkHeader: c"ff"
          else: c"40",
        hoverColor:
          if darkHeader: c"ff"
          else: c"40",
        pressedColor:
          if darkHeader: c"ff"
          else: c"40",
        backgroundColor:
          if darkHeader: c"20"
          else: c"ff",
        hoverBackgroundColor:
          if darkHeader: c"30"
          else: c"f0",
        pressedBackgroundColor:
          if darkHeader: c"26"
          else: c"d0",
      ),
      
      accentButton: ButtonStyle(
        color:
          if darkHeader: c"ff"
          else: c"40",
        hoverColor: c"ff",
        pressedColor: c"ff",
        backgroundColor:
          if darkHeader: c"20"
          else: c"ff",
        hoverBackgroundColor: c"#E03649",
        pressedBackgroundColor: c"#C11B2D",
      ),
      
      typeface: typeface,
    )
  )
