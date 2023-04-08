{.used.}
import ../qt

type DPage* = object
  switcher*: QJSValue

qobject DPage of QQuickItem:
  property QJSValue switcher: auto
  
  proc `=new` =
    this[].clip = true

registerInQml DPage, "DMusic.Components", 1, 0
