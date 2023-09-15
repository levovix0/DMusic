import asyncdispatch
import pixie, pixie/fileformats/svg
import ./[uibase, mouseArea, style, animations, dmusicGlobals]
import ../[api, utils, configuration, audio]
import ../musicProviders/[yandexMusic]

type
  PlaylistEntry* = ref object of Uiobj
    playing*: Property[bool]
    selected*: Property[bool]
    playlist*: Property[api.Playlist]
    style*: Property[Style]
    
    coverRequestCanceled: ref bool


method recieve*(this: PlaylistEntry, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style[] = style
  procCall this.super.recieve(signal)


proc newPlaylistEntry*: PlaylistEntry =
  result = PlaylistEntry()
  
  result.makeLayout:
    this.w[] = 115
    this.binding h: this.w[] + name.h[] + 10

    g_player.whenNotNilDo root:
      this.binding playing: g_player{}.outAudioStream.state[] == playing

    - newUiRectShadow():
      this.fill(cover, -8)
      this.binding radius: cover.radius[]
      this.blurRadius[] = 8
      this.color[] = color(0, 0, 0, 0.2)

    - newUiClipRect() as cover:
      this.fillHorizontal(parent)
      this.binding h: this.w[]
      this.radius[] = 5

      - newUiMouseArea() as mouse:
        this.fill(parent)

        - newUiImage():
          this.fill(parent)

          this.image = emptyCover.parseSvg(115, 115).newImage
          
          root.playlist.changed.connectTo root:
            if root.coverRequestCanceled != nil:
              root.coverRequestCanceled[] = false
            
            if root.playlist[] == nil:
              this.image = emptyCover.parseSvg(115, 115).newImage
            else:
              root.coverRequestCanceled = new bool
              let p = (proc(root: PlaylistEntry, this: UiImage, playlist: api.Playlist) {.async.} =
                try:
                  let cover = playlist.cover(cancel = root.coverRequestCanceled).await.resize(115, 115)
                  this.image =
                    if cover == nil: emptyCover.parseSvg(115, 115).newImage
                    else: cover
                except RequestCanceled:
                  discard
              )(root, this, e)
              when isMainModule: waitFor p
              else: asyncCheck p

        - newUiRect():
          this.fill(parent)
          this.binding color:
            if playMouse.hovered[] or playMouse.pressed[]: color(0, 0, 0, 0.5)
            elif mouse.hovered[] or root.selected[]: color(0, 0, 0, 0.4)
            else: color(0, 0, 0, 0)
          
          - this.color.transition(0.4's):
            this.interpolation[] = outQubicInterpolation
        
        - newUiSvgImage():
          this.centerIn parent
          this.binding image:
            if root.selected[] and root.playing[]: static(staticRead "../../../resources/player/pause.svg")
            else: static(staticRead "../../../resources/player/play.svg")
          this.binding color:
            if playMouse.pressed[]: config.colorAccentDark[].parseHtmlColor.darken(0.2)
            elif playMouse.hovered[]: config.colorAccentDark[].parseHtmlColor
            elif mouse.hovered[] or root.selected[]: color(1, 1, 1, 1)
            else: color(1, 1, 1, 0)

          var scale = 0.7'f32.property
          this.bindingProperty scale:
            if playMouse.pressed[]: 0.9'f32
            elif playMouse.hovered[]: 1'f32
            else: 0.7'f32
          
          this.binding w: 25'f32 * scale[]
          this.binding h: 30'f32 * scale[]
          
          - this.color.transition(0.4's):
            this.interpolation[] = outQubicInterpolation
          
          - this.w.transition(0.4's):
            this.interpolation[] = outBounceInterpolation
          
          - this.h.transition(0.4's):
            this.interpolation[] = outBounceInterpolation
          
          - newUiMouseArea() as playMouse:
            this.fill(parent, -2)

            this.mouseDownAndUpInside.connectTo root:
              this.parentUiWindow.recieve(PlaylistEntrySignal(
                playlist: root.playlist[],
                action:
                  if root.playing[]: PlaylistEntryAction.pause
                  else: PlaylistEntryAction.play,
              ))


    - newUiText() as name:
      this.centerX = parent.center
      this.top = cover.bottom + 5
      this.bounds[] = vec2(115, 100)
      this.hAlign[] = CenterAlign
      this.binding text: (if root.playlist[] != nil: root.playlist[].title else: "")
      this.bindFont(root.style, 14)


when isMainModule:
  preview(clearColor = color(1, 1, 1, 1), margin = 20,
    withWindow = proc: Uiobj =  
      var x = newPlaylistEntry()
      # x.playing[] = false
      x.playlist[] = try: api.Playlist personalPlaylists().waitFor[0].playlist except: nil
      
      let styl = makeStyle(false, false)
      x.recieve(StyleChanged(fullStyle: styl, style: styl.window))
      
      x.onSignal.connectTo x:
        case e
        of of PlaylistEntrySignal(playlist: @p, action: @act):
          x.selected[] = true
          x.playing[] = act == play
      x
  )
