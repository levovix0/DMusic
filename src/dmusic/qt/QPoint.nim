import nimqt/qpoint

{.push, header: "QtCore/qpoint.h".}
proc `+`*(this: QPoint, p: QPoint): QPoint {.importcpp: "(# + #)".}
proc `-`*(this: QPoint, p: QPoint): QPoint {.importcpp: "(# - #)".}
{.pop.}
