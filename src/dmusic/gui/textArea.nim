import times
import siwin
import ./[uibase, mouseArea, globalShortcut]

type
  Blinking* = object
    enabled*: Property[bool] = true.property
    period*: Property[Duration] = initDuration(milliseconds = 500).property

    time: Property[Duration]


  UiTextAreaInteraction* = enum
    textInput
    activatingUsingMouse
    deactivatingUsingMouse
    deactivatingUsingEsc
    navigationUsingArrows
    navigationUsingMouse
    selecting
    selectingWordsByDobleClick
    selectingAllTextByDobleClick
    selectingAllTextByTripleClick
    # note: implement selecting all text on activation by yourself if you need it
    copyingUsingCtrlC
    copyingUsingSelection
    pastingUsingCtrlV
    pastingUsingMiddleMouseButton
    deactivatingAndActivatingUsingMiddleMouseButton

  UiTextArea* = ref object of Uiobj
    cursorObj*: CustomProperty[UiObj]
    selectionObj*: CustomProperty[Uiobj]
    textObj*: CustomProperty[UiText]

    active*: Property[bool]
    text*: Property[string]
    cursorPos*: CustomProperty[int]
    blinking*: Blinking
    allowedInteractions*: Property[set[UiTextAreaInteraction]] = {
      UiTextAreaInteraction.textInput,
      activatingUsingMouse,
      deactivatingUsingMouse,
      deactivatingUsingEsc,
      navigationUsingArrows,
      navigationUsingMouse,
      selecting,
      selectingWordsByDobleClick,
      selectingAllTextByTripleClick,
      copyingUsingCtrlC,
      copyingUsingSelection,
      pastingUsingCtrlV,
      pastingUsingMiddleMouseButton,
      deactivatingAndActivatingUsingMiddleMouseButton,
    }.property
    
    m_cursorPos: int


proc `mod`(a, b: Duration): Duration =
  result = a
  while result > b:
    result -= b


method init*(this: UiTextArea) =
  procCall this.Uiobj.init()
  this.cursorPos = CustomProperty[int](
    get: proc(): int = this.m_cursorPos,
    set: proc(x: int) = this.m_cursorPos = x.max(0).min(this.text[].len),
  )


proc newUiTextArea*(): UiTextArea =
  result = UiTextArea()

  result.makeLayout:
    this.withWindow win:
      win.onTick.connectTo this:
        this.blinking.time[] = (this.blinking.time + e.deltaTime) mod (this.blinking.period[] * 2)

    - newUiMouseArea():
      this.fill parent

      this.pressed.changed.connectTo root:  # temporary
        if this.pressed[]:
          root.active[] = true

      - newUiClipRect():
        this.fill parent

        root.textObj --- newUiText():
          this.binding text: root.text[]

        root.cursorObj --- newUiRect().UiObj:
          this.fillVertical parent
          this.w[] = 2
          this.binding visibility:
            if root.active[]:
              if root.blinking.enabled[]:
                if root.blinking.time[] <= root.blinking.period[]:
                  Visibility.visible
                else:
                  Visibility.hiddenTree 
              else: Visibility.visible
            else: Visibility.hiddenTree
          
          - globalShortcut({Key.a}):  # temporary
            this.activated.connectTo root:
              root.cursorPos[] = root.cursorPos[] - 1
          - globalShortcut({Key.d}):  # temporary
            this.activated.connectTo root:
              root.cursorPos[] = root.cursorPos[] + 1

          this.binding x:
            let arrangement = root.textObj{}.arrangement[]
            if arrangement != nil:
              let pos = root.cursorPos[]
              if pos > arrangement.positions.high:
                arrangement.layoutBounds.x
              else:
                arrangement.positions[pos].x
            else: 0

