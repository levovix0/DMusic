import siwin, fusion/matching
import uibase
export MouseButton, MouseMoveEvent

type
  UiMouseArea* = ref object of Uiobj
    acceptedButtons*: Property[set[MouseButton]] = {MouseButton.left}.property
    ignoreHandling*: Property[bool]
      ## don't stop propogating signals even they are handled
    
    pressed*: Property[bool]
    hovered*: Property[bool]

    mouseMove*: Event[MouseMoveEvent]
    clicked*: Event[ClickEvent]
    mouseButton*: Event[MouseButtonEvent]
    mouseDownAndUpInside*: Event[void]
    dragged*: Event[IVec2]
    cursor*: ref Cursor
      ## mouse moved while in this area (or outside this area but pressed)
    pressedButtons: set[MouseButton]
    pressedPos: IVec2
    dragStarted: bool


method recieve*(this: UiMouseArea, signal: Signal) =
  procCall this.super.recieve(signal)

  if this.visibility != collapsed:
    template handlePositionalEvent(ev, ev2) =
      let e {.cursor.} = (ref ev)signal.WindowEvent.event
      let pos = this.xy[].posToGlobal(this.parent)
      if e.window.mouse.pos.x.float32 in pos.x..(pos.x + this.w[]) and e.window.mouse.pos.y.float32 in pos.y..(pos.y + this.h[]):
        this.ev2.emit e[]
    
    if signal of WindowEvent and signal.WindowEvent.event of MouseButtonEvent:
      handlePositionalEvent MouseButtonEvent, mouseButton
    
    elif signal of WindowEvent and signal.WindowEvent.event of ClickEvent:
      handlePositionalEvent ClickEvent, clicked
    
    elif signal of WindowEvent and signal.WindowEvent.event of MouseMoveEvent:
      let e {.cursor.} = (ref MouseMoveEvent)signal.WindowEvent.event
      let pos = this.xy[].posToGlobal(this.parent)
      if e.pos.x.float32 in pos.x..(pos.x + this.w[]) and e.pos.y.float32 in pos.y..(pos.y + this.h[]):
        this.hovered[] = true
      else:
        this.hovered[] = false
    
    case signal

    of of WindowEvent(event: @ea is of MouseMoveEvent(), handled: false, fake: false):
      let e = (ref MouseMoveEvent)ea
      if this.pressed[] or this.hovered[]:
        if this.mouseMove.hasHandlers:
          signal.WindowEvent.handled = true
        this.mouseMove.emit(e[])

      if this.pressed[]:
        if not this.dragStarted:
          this.dragStarted = true
          if this.dragged.hasHandlers:
            signal.WindowEvent.handled = true
          this.dragged.emit(this.pressedPos)

    of of WindowEvent(event: @ea is of MouseButtonEvent(), handled: false):
      if this.visibility != collapsed:
        let e = (ref MouseButtonEvent)ea
        if e.button in this.acceptedButtons[]:
          if e.pressed:
            if this.hovered[]:
              this.pressedButtons.incl e.button
              this.pressed[] = true
              this.pressedPos = e.window.mouse.pos + e.window.pos
          else:
            this.pressedButtons.excl e.button
            if this.pressedButtons == {}:
              if this.pressed[]:
                this.pressed[] = false
                this.dragStarted = false
                if this.hovered[] and not e.generated:
                  this.mouseDownAndUpInside.emit()
  
  case signal
  of of VisibilityChanged(visibility: @e):
    if e == collapsed:
      this.hovered[] = false


proc newUiMouseArea*(): UiMouseArea = new result
