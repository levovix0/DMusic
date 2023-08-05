import times, asyncdispatch, strutils, macros
import siwin
import ./[configuration, utils, yandexMusic]
import ./gui/[uibase, window, windowHeader, style, globalShortcut]


proc gui*: string =
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

    - newWindowHeader():
      this.anchors.fillHorizontal(root)
      this.box.h = 40
    
    - UiImage():  # temporary
      this.box.y = 100
      this.image = app.decodeImage


  notifyLanguageChanged &= proc() =
    globalLocale = (($config.language, ""), LocaleTable.default)
  
  notifyCsdChanged &= proc() =
    let icon =
      when defined(windows): decodeImage(static(staticRead "../../resources/app.svg"))
      else: decodeImage(static(staticRead "../../resources/app-papirus.svg"))
    win.siwinWindow.icon = (icon.data.toBgrx.toOpenArray(0, icon.data.high), ivec2(icon.width.int32, icon.height.int32))

  proc makeStyle(darkTheme, darkHeader: bool): FullStyle =
    macro c(g: static string): Col =
      let c = g.parseHexInt.byte
      newCall(bindSym"color", newCall(bindSym"rgbx", newLit c, newLit c, newLit c, newLit 255))
    
    FullStyle(
      window: Style(
        color:
          if darkTheme: c"ff"
          else: c"40",
        backgroundColor:
          if darkTheme: c"20"
          else: c"ff",
        # buttonBackgroundColor:
        #   if darkTheme: c"20"
        #   else: c"ff",
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
      )
    )


  var style = makeStyle(config.darkTheme, config.darkHeader)

  notifyDarkThemeChanged &= proc() =
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow

  notifyDarkHeaderChanged &= proc() =
    style = makeStyle(config.darkTheme, config.darkHeader)
    win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))
    redraw win.siwinWindow
  
  notifyLanguageChanged()
  notifyCsdChanged()
  win.recieve(StyleChanged(sender: win, fullStyle: style, style: style.window))


  var darkTime = config.darkTheme

  win.siwinWindow.firstStep(makeVisible=true)

  while win.siwinWindow.opened:
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
