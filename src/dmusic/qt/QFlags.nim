import nimqt/qflags

{.push, header: "QtCore/qflags.h".}
proc `==`*(a: QFlags, b: QFlags): bool {.importcpp: "(# == #)".}
{.pop.}
