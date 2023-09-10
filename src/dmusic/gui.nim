import times, asyncdispatch, strutils, macros, std/importutils, heapqueue, deques, selectors
import siwin
import ./[configuration, utils]
import ./musicProviders/[yandexMusic]
import ./gui/[uibase, style, window, windowHeader, globalShortcut, player, textArea]

privateAccess PDispatcher  # to check if not empty (overthise it will spam error logs)


proc gui*: string =
  globalLocale = (($config.language, ""), LocaleTable.default)
  
  let root = Uiobj()
  let win = createWindow(root)
  
  root.makeLayout:
    - globalShortcut({Key.t}):  # temporary
      this.activated.connectTo this:
        config.darkTheme[] = not config.darkTheme

    - globalShortcut({Key.h}):  # temporary
      this.activated.connectTo this:
        config.darkHeader[] = not config.darkHeader

    - globalShortcut({Key.a}):  # temporary
      this.activated.connectTo this:
        config.csd[] = not config.csd

    - globalShortcut({Key.s}):  # temporary
      this.activated.connectTo this:
        config.window_maximizeButton[] = not config.window_maximizeButton

    - newWindowHeader():
      this.anchors.fillHorizontal(root)
      this.box.h = 40

    - newPlayer():
      this.anchors.fillHorizontal(root)
      this.box.h = 66
      this.anchors.bottom = Anchor(obj: parent, offsetFrom: `end`, offset: 0)
    
    - newUiRect():  # todo: UiRectBorder
      this.anchors.fillHorizontal(parent, 400)
      this.anchors.centerY = parent.center
      this.box.h = 40
      this.color[] = color(0.5, 0.5, 0.5)
      this.radius[] = 6

      - newUiRect():
        this.anchors.fill(parent, 1)
        this.color[] = color(1, 1, 1)
        this.radius[] = 5
      
        - newUiTextArea():
          this.anchors.fill(parent, 4, 2)
          this.text[] = "hello"
          this.onSignal.connectTo this:
            case e
            of of StyleChanged(style: @style):
              this.textObj[].font[] = newFont(style.typeface).buildIt:
                it.size = 32



  config.language.changed.connectTo win:
    globalLocale = (($config.language, ""), LocaleTable.default)
  
  let icon =
    when defined(windows): decodeImage(static(staticRead "../../resources/app.svg"))
    else: decodeImage(static(staticRead "../../resources/app-papirus.svg"))
  win.siwinWindow.icon = (icon.data.toBgrx.toOpenArray(0, icon.data.high), ivec2(icon.width.int32, icon.height.int32))


  const robotoFont = staticRead "../../resources/fonts/Roboto-Regular.ttf"
  let typeface = parseTtf(robotoFont)

  proc makeStyle(darkTheme, darkHeader: bool): FullStyle =
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


  var style = makeStyle(config.darkTheme, config.darkHeader)

  config.darkTheme.changed.connectTo win:
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow

  config.darkHeader.changed.connectTo win:
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow
  
  config.language.changed.emit(config.language)
  win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))


  var darkTime = config.darkTheme[]

  win.siwinWindow.firstStep(makeVisible=true)

  while win.siwinWindow.opened:
    let p = getGlobalDispatcher()
    let c =
      when defined(windows): p.timers.len == 0 and p.callbacks.len == 0
      else: p.selector.isEmpty() and p.timers.len == 0 and p.callbacks.len == 0
    if not c:
      try: poll()
      except CatchableError:
        logger.log(lvlError, "Error during async operation: ", getCurrentExceptionMsg())
      except Defect:
        logger.log(lvlError, "Defect during async operation: ", getCurrentExceptionMsg())
        raise
    
    garbageCollect coverCache

    if config.themeByTime:
      if now().hour in 7..18:
        if darkTime: config.darkTheme[] = false
        darkTime = false
      else:
        if not darkTime: config.darkTheme[] = true
        darkTime = true
    
    win.siwinWindow.step
