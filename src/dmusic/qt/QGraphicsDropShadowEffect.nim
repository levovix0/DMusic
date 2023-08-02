import nimqt/[qgraphicseffect, qcolor]
export qgraphicseffect, qcolor

{.push, header: "QtWidgets/qgraphicseffect.h".}
proc newQGraphicsDropShadowEffect*(): ptr QGraphicsDropShadowEffect {.importcpp: "new QGraphicsDropShadowEffect(@)".}
proc setBlurRadius*(effect: ptr QGraphicsDropShadowEffect, radius: float) {.importcpp: "#.setBlurRadius(@)".}
proc setXOffset*(effect: ptr QGraphicsDropShadowEffect, offset: float) {.importcpp: "#.setXOffset(@)".}
proc setYOffset*(effect: ptr QGraphicsDropShadowEffect, offset: float) {.importcpp: "#.setYOffset(@)".}
proc setColor*(effect: ptr QGraphicsDropShadowEffect, radius: QColor) {.importcpp: "#.setColor(@)".}
{.pop.}
