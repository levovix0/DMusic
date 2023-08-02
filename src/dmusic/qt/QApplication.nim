import nimqt/[qapplication]
export qapplication

{.push, header: "QtWidgets/qapplication.h".}
proc `appName=`*(app: ptr QApplication, name: QString) {.importcpp: "#.setApplicationName(@)".}
proc `organizationName=`*(app: ptr QApplication, name: QString) {.importcpp: "#.setOrganizationName(@)".}
proc `organizationDomain=`*(app: ptr QApplication, domain: QString) {.importcpp: "#.setOrganizationDomain(@)".}
proc `icon=`*(this: ptr QApplication, v: QIcon) {.importcpp: "#.setWindowIcon(@)".}
{.pop.}
