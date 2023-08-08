import times, asyncdispatch, strutils, macros, std/importutils, heapqueue, deques, selectors
import siwin
import ./[configuration, utils, yandexMusic]
import ./gui/[uibase, window, windowHeader, style, globalShortcut]

privateAccess PDispatcher  # to check if not empty (overthise it will spam error logs)


proc gui*: string =
  globalLocale = (($config.language, ""), LocaleTable.default)
  
  let root = Uiobj()
  let win = createWindow(root)

  const app = staticRead "../../resources/app-papirus.svg"  # temporary
  
  root.makeLayout:
    - globalShortcut({Key.t}):  # temporary
      this.action = proc =
        config.darkTheme = not config.darkTheme

    - globalShortcut({Key.h}):  # temporary
      this.action = proc =
        config.darkHeader = not config.darkHeader

    - globalShortcut({Key.a}):  # temporary
      this.action = proc =
        config.csd = not config.csd

    - globalShortcut({Key.s}):  # temporary
      this.action = proc =
        config.window_maximizeButton = not config.window_maximizeButton

    - newWindowHeader():
      this.anchors.fillHorizontal(root)
      this.box.h = 40
    
    - UiImage():  # temporary
      this.box.y = 100
      this.image = app.decodeImage


  notifyLanguageChanged.connectTo win:
    globalLocale = (($config.language, ""), LocaleTable.default)
  
  let icon =
    when defined(windows): decodeImage(static(staticRead "../../resources/app.svg"))
    else: decodeImage(static(staticRead "../../resources/app-papirus.svg"))
  win.siwinWindow.icon = (icon.data.toBgrx.toOpenArray(0, icon.data.high), ivec2(icon.width.int32, icon.height.int32))

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
        hoverButtonBackgroundColor:
          if darkTheme: c"30"
          else: c"f0",
      ),
      header: Style(
        color:
          if darkHeader: c"ff"
          else: c"40",
        backgroundColor:
          if darkHeader: c"20"
          else: c"ff",
        buttonBackgroundColor:
          if darkHeader: c"20"
          else: c"ff",
        hoverButtonBackgroundColor:
          if darkHeader: c"30"
          else: c"f0",
        pressedButtonBackgroundColor:
          if darkHeader: c"26"
          else: c"d0",
        accentButtonBackgroundColor:
          if darkHeader: c"20"
          else: c"ff",
        accentHoverButtonBackgroundColor: c"#E03649",
        accentPressedButtonBackgroundColor: c"#C11B2D",
      )
    )


  var style = makeStyle(config.darkTheme, config.darkHeader)

  notifyDarkThemeChanged.connectTo win:
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow

  notifyDarkHeaderChanged.connectTo win:
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow
  
  notifyLanguageChanged.emit(config.language)
  win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))


  var darkTime = config.darkTheme

  win.siwinWindow.firstStep(makeVisible=true)

  while win.siwinWindow.opened:
    let p = getGlobalDispatcher()
    if not(p.selector.isEmpty() and p.timers.len == 0 and p.callbacks.len == 0):
      try: poll()
      except CatchableError:
        logger.log(lvlError, "Error during async operation: ", getCurrentExceptionMsg())
      except Defect:
        logger.log(lvlError, "Defect during async operation: ", getCurrentExceptionMsg())
        raise
    
    garbageCollect coverCache

    if config.themeByTime:
      if now().hour in 7..18:
        if darkTime: config.darkTheme = false
        darkTime = false
      else:
        if not darkTime: config.darkTheme = true
        darkTime = true
    
    win.siwinWindow.step
