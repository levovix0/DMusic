import asyncdispatch, times
import pixie/fileformats/svg, siwin
import ../[configuration, api, utils, audio, yandexMusic]
import ./[uibase, style, globalShortcut]

type
  Player* = ref object of Uiobj
    style*: Property[Style]
    currentTrack*: Property[api.Track]
    coverRequestCanceled, audioRequestCanceled: ref bool
    outAudioStream: OutAudioStream


proc formatSeconds(secs: int): string =
  let ms = initDuration(seconds = secs)
  if ms.inHours != 0: ms.format("h:mm:ss")
  else:               ms.format("m:ss")


method recieve*(this: Player, signal: Signal) =
  case signal
  of of StyleChanged(fullStyle: @style):
    this.style[] = style.panel
    signal.StyleChanged.withStyleForChilds panel:
      procCall this.super.recieve(signal)
  of of AttachedToWindow(window: @window):
    window.onTick.connectTo this:
      this.outAudioStream.emitEvents()
    procCall this.super.recieve(signal)
  else:
    procCall this.super.recieve(signal)


proc newPlayer*(): Player =
  result = Player()
  result.makeLayout:    
    root.outAudioStream = newOutAudioStream()
    root.outAudioStream.binding volume: config.volume[]
    do: discard
    do: false
    root.currentTrack.changed.connectTo root.outAudioStream:
      this.state[] = paused
      if root.audioRequestCanceled != nil: root.audioRequestCanceled[] = true
      root.audioRequestCanceled = new bool
      asyncCheck: (proc(this: OutAudioStream, track: api.Track, root: Player) {.async.} =
        if track.kind != yandex: return
        try:
          let audio = request(track.audio.await, cancel = root.audioRequestCanceled).await
          this.playTrackFromMemory(audio)
          this.state[] = playing
        except RequestCanceled:
          discard
      )(this, e, root)

    - UiRect():
      this.anchors.fill(parent)
      this.binding color: (if parent.style[] != nil: parent.style[].backgroundColor else: color(0, 0, 0))

      - UiImage() as cover:
        this.anchors.centerY = parent.center
        this.box.w = 50
        this.box.h = 50
        this.anchors.left = parent.left(8)
        this.radius[] = 7.5
        
        this.image = emptyCover.parseSvg(50, 50).newImage
        root.currentTrack.changed.connectTo this:
          if root.coverRequestCanceled != nil: root.coverRequestCanceled[] = true
          root.coverRequestCanceled = new bool
          asyncCheck: (proc(this: UiImage, track: api.Track) {.async.} =
            if track == nil:
              this.image = emptyCover.parseSvg(50, 50).newImage
            else:
              try:
                this.image = e.cover(lowQualityCover, root.coverRequestCanceled).await
              except RequestCanceled:
                discard
            redraw this
          )(this, e)
    
      - UiText() as title:
        this.anchors.bottom = parent.center(-2)
        this.anchors.left = cover.right(11)
        this.binding color: (if root.style[] != nil: root.style[].color else: color(0, 0, 0))
        this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].title else: "Title")
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 14
            f
          else: nil
    
      - UiText() as comment:
        this.anchors.bottom = parent.center(-2)
        this.anchors.left = title.right(5)
        this.binding color: (if root.style[] != nil: root.style[].color3 else: color(0, 0, 0))
        this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].comment else: "Comment")
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 14
            f
          else: nil
    
      - UiText() as authors:
        this.anchors.top = parent.center(3)
        this.anchors.left = cover.right(11)
        this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
        this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].artists else: "Authors")
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 12
            f
          else: nil

      - Uiobj() as playerLineMouseArea:
        this.box.h = 16
        this.onReposition.connectTo this:
          this.box.w = this.parent.box.w / 2.7
        this.box.y = 42
        this.anchors.centerX = parent.center

        - UiRect() as playerLineBackground:
          this.box.h = 4
          this.anchors.fillHorizontal parent
          this.anchors.centerY = parent.center
          this.radius[] = 2
          this.binding color: (if root.style[] != nil: root.style[].itemBackground else: color(0, 0, 0))

          - UiRect() as playerLine:
            this.box.h = parent.box.h
            this.radius[] = 2
            this.binding color:
              if root.style[] != nil:
                if playerLineMouseArea.hovered[]: root.style[].accent
                else: root.style[].itemColor
              else: color(0, 0, 0)
            
            playerLineMouseArea.clicked.connectTo this:
              root.outAudioStream.position[] = e.pos.vec2.posToLocal(this.parent).x / this.parent.box.w

            root.outAudioStream.position.changed.connectTo this:
              this.box.w = this.parent.box.w * e
              startReposition root
          
          - UiRectShadow() as pointShadow:
            this.binding visibility: (if root.style[] != nil and root.style[].itemDropShadow and playerLineMouseArea.hovered[]: Visibility.visible else: Visibility.hidden)
            this.box.w = 18
            this.box.h = 18
            this.blurRadius[] = 3
            this.radius[] = 6
            this.color[] = color(0, 0, 0, 0.2)
            this.anchors.centerY = playerLine.center
            this.anchors.centerX = playerLine.right

          - UiRect():
            this.binding visibility: (if playerLineMouseArea.hovered[]: Visibility.visible else: Visibility.hidden)
            this.anchors.centerIn pointShadow
            this.box.w = 12
            this.box.h = 12
            this.radius[] = 6
            this.color[] = color(1, 1, 1)
      
      - UiText():
        this.anchors.right = playerLineMouseArea.left(-14)
        this.anchors.centerY = playerLineMouseArea.center
        this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
        this.binding text: (root.outAudioStream.duration[].inSeconds.float * root.outAudioStream.position[]).int.formatSeconds
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 12
            f
          else: nil
      
      - UiText():
        this.anchors.left = playerLineMouseArea.right(14)
        this.anchors.centerY = playerLineMouseArea.center
        this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
        this.binding text: root.outAudioStream.duration[].inSeconds.formatSeconds
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 12
            f
          else: nil
    
    - UiRect():
      this.anchors.fillHorizontal(parent)
      this.anchors.top = Anchor(obj: result, offsetFrom: start, offset: -1)
      this.box.h = 2
      this.binding color: (if parent.style[] != nil: parent.style[].borderColor else: color(0, 0, 0))
      this.binding visibility: (if parent.style[] != nil and parent.style[].borders: Visibility.visible else: Visibility.hidden)
      
    - globalShortcut({Key.space}):
      this.activated.connectTo root:
        this.outAudioStream.state[] = case this.outAudioStream.state[]
        of playing: paused
        of paused: playing
    
    - globalShortcut({Key.up}):
      this.activated.connectTo root:
        config.volume[] = (config.volume[] + 0.05).max(0).min(1)
    
    - globalShortcut({Key.down}):
      this.activated.connectTo root:
        config.volume[] = (config.volume[] - 0.05).max(0).min(1)
    
    root.currentTrack[] = yandexTrack(76130675)
    waitFor fetch root.currentTrack[]
    root.currentTrack.changed.emit(root.currentTrack[])
