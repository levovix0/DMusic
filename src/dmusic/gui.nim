import std/exitprocs, os, times
import nimqt, asyncdispatch
import nimqt/[qpushbutton, qtimer]
import ./[configuration, utils, yandexMusic]
import ./qt/[QApplication]
import ./gui/[window, windowHeader]


nimqt.init()
let qapp* = newQApplication(commandLineParams())


inheritQObject(App, QObject):
  slot_decl on_helloWorld_clicked()

proc on_helloWorld_clicked(this: ptr App) =
  let sender = cast[ptr QPushButton](this.get_sender())
  sender.setText(Q "Привет, мир!")


var gui_on_timer_timeout: proc()


proc gui*: string =
  qapp.appName = Q "DMusic"
  qapp.organizationName = Q "DTeam"
  qapp.organizationDomain = Q "levovix.ru"


  notifyLanguageChanged &= proc() =
    globalLocale = (($config.language, ""), LocaleTable.default)
  
  # notifyCsdChanged &= proc() =
  #   when defined(windows): qapp.icon = newQIcon(Q ":resources/app.svg")
  #   else: qapp.icon = newQIcon(Q ":resources/app-papirus.svg")

  notifyLanguageChanged()
  notifyCsdChanged()


  var darkTime = config.darkTheme

  let timer = newQTimer()
  proc on_timer_timeout() {.exportc, cdecl.} =
    gui_on_timer_timeout()
  connect(timer, SIGNAL "timeout()", on_timer_timeout)

  gui_on_timer_timeout = proc =
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
  

  let app = newApp()
  let root = newQWidget()

  root.makeLayout:
    - createWindowHeader()
    - newQPushButton(Q "Hello, world!"):
      connect(SIGNAL "clicked()", app, SLOT "on_helloWorld_clicked()")


  const styleSheet = staticRead("../../resources/themes/dark.qss")
  qapp.setStyleSheet(Q styleSheet)


  show createWindow(root)
  setProgramResult qapp.exec
