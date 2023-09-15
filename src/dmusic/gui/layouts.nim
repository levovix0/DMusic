import sequtils
import uibase

type
  LayoutOrientation* = enum
    horisontal
    vertical

  LayoutAlignment* = enum
    start
    center
    `end`

  Layout* = ref object of Uiobj
    orientation*: Property[LayoutOrientation]
    spacing*, wrapSpacing*: Property[float]
    fillWithSpaces*, wrapFillWithSpaces*: Property[bool]
    hugContent*, wrapHugContent*: Property[bool]
    alignment*, wrapAlignment*: Property[LayoutAlignment]
    
    wrap*: Property[bool]
      ## become "grid"
    elementsBeforeWrap*: Property[int]
    lengthBeforeWrap*: Property[float]

    inRepositionProcess: bool
  
  InLayout* = ref object of Uiobj
    alignment*: Property[LayoutAlignment]
    fillContainer*: Property[bool]
    
    isChanginW, isChanginH: bool


proc reposition(this: Layout) =
  if this.inRepositionProcess: return
  this.inRepositionProcess = true
  defer: this.inRepositionProcess = false

  proc get_w(child: Uiobj): float32 =
    case this.orientation[]
    of horisontal: child.w[]
    of vertical: child.h[]

  proc get_h(child: Uiobj): float32 =
    case this.orientation[]
    of horisontal: child.h[]
    of vertical: child.w[]

  proc set_x(child: Uiobj, v: float32) =
    case this.orientation[]
    of horisontal: child.x[] = child.x[] + v
    of vertical: child.y[] = child.y[] + v

  proc set_y(child: Uiobj, v: float32) =
    case this.orientation[]
    of horisontal: child.y[] = child.y[] + v
    of vertical: child.x[] = child.x[] + v

  proc set_h(child: Uiobj, v: float32) =
    case this.orientation[]
    of horisontal: child.h[] = v
    of vertical: child.w[] = v

  var rows: seq[tuple[childs: seq[Uiobj], freeSpace: float32, h: float32]] = @[(@[], 0'f32, 0'f32)]

  block:
    var
      i = 0
      x = 0'f32
      h = 0'f32

    for child in this.childs:
      if child.visibility == collapsed: continue
      if x != 0: x += this.spacing[]
      x += child.get_w
      inc i

      if this.wrap[] and
        (
          (this.elementsBeforeWrap[] > 0 and this.elementsBeforeWrap[] > i) or
          (this.lengthBeforeWrap[] > 0 and this.lengthBeforeWrap[] > x)
        ):
        rows[^1].h = h
        i = 0
        x = 0
        h = 0
        rows.add (@[], this.w[], 0'f32)
      else:
        if x != child.get_w + this.spacing[]:
          rows[^1].freeSpace -= this.spacing[]
      
      rows[^1].childs.add child
      if not(child of InLayout):
        h = max(h, child.get_h)
      rows[^1].freeSpace -= child.get_w

  block:
    var y = 0'f32
    let freeYSpace =
      if this.wrapFillWithSpaces[]: rows.mapit(it.h).foldl(a + this.wrapSpacing[] + b)
      else: 0'f32
    for (row, freeSpace, h) in rows:
      var
        x =
          if this.fillWithSpaces[]: 0'f32
          else:
            case this.alignment[]
            of start: 0'f32
            of center: freeSpace / 2
            of `end`: freeSpace

      let freeSpace =
        if this.fillWithSpaces[]: freeSpace
        else: 0'f32
      
      for child in row:
        child.set_x(x)
        
        if child of InLayout:
          if child.InLayout.fillContainer[]:
            child.set_h(this.get_h)
            child.set_y(y)
          else:
            case child.InLayout.alignment[]
            of start:
              child.set_y(y)
            of center:
              child.set_y(y + h / 2 - child.get_h / 2)
            of `end`:
              child.set_y(y + h - child.get_h)
        
        else:
          child.set_y(y)
        
        x += child.get_w + this.spacing[] + freeSpace / row.len.float32
      y += h + this.wrapSpacing[] + freeYSpace / rows.len.float32



method init*(this: Layout) =
  if this.initialized: return
  procCall this.super.init
