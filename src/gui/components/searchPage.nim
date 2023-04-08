{.used.}
import ../qt
import page

type SearchPage* = object
  placeholder*: QQuickItem


qobject SearchPage of DPage.Ct:
  proc `=new` = 
    discard
