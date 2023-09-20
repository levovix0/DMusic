import times, asyncdispatch, std/importutils, heapqueue, deques, selectors
import siwin, fusion/matching
import ./[configuration, utils]
import ./musicProviders/[yandexMusic]
import sigui/[uibase, globalShortcut]
import ./gui/[style, window, windowHeader, player, textArea, dmusicGlobals]

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
      this.fillHorizontal(root)
      this.h[] = 40

    - newPlayer():
      this.fillHorizontal(root)
      this.h[] = 66
      this.bottom = Anchor(obj: parent, offsetFrom: `end`, offset: 0)
      g_player[] = this
    
    - UiRectStroke():
      this.fillHorizontal(parent, 400)
      this.centerY = parent.center
      this.h[] = 40
      this.color[] = color(0.5, 0.5, 0.5)
      this.radius[] = 5

      - newUiTextArea():
        this.fill(parent, 4, 2)
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
