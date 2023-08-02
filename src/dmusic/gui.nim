import times, asyncdispatch, pixie
import siwin
import ./[configuration, utils, yandexMusic]
import ./gui/[uibase, window, windowHeader]


proc gui*: string =
  let root = Uiobj()
  
  let windowHandle = newWindowHeader()
  root.addChild windowHandle
  windowHandle.anchors.fillHorizontal(root)
  windowHandle.box.h = 40

  let win = createWindow(root)


  notifyLanguageChanged &= proc() =
    globalLocale = (($config.language, ""), LocaleTable.default)
  
  notifyCsdChanged &= proc() =
    let icon =
      when defined(windows): decodeImage(static(staticRead "../../resources/app.svg"))
      else: decodeImage(static(staticRead "../../resources/app-papirus.svg"))
    win.siwinWindow.icon = (icon.data.toBgrx.toOpenArray(0, icon.data.high), ivec2(icon.width.int32, icon.height.int32))

  notifyLanguageChanged()
  notifyCsdChanged()


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
