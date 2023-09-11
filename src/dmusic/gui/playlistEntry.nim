import asyncdispatch
import pixie, pixie/fileformats/svg
import ./[uibase, mouseArea, style]
import ../[api, utils]
import ../musicProviders/[yandexMusic]

type
  PlaylistEntry* = ref object of Uiobj
    playing*: Property[bool]
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

    - newUiRectShadow():
      this.fill(cover, -8)
      this.binding radius: cover.radius[]
      this.blurRadius[] = 8
      this.color[] = color(0, 0, 0, 0.2)

    - newUiClipRect() as cover:
      this.fillHorizontal(parent)
      this.binding h: this.w[]
      this.radius[] = 5

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
            waitFor: (proc(root: PlaylistEntry, this: UiImage, playlist: api.Playlist) {.async.} =
              try:
                let cover = playlist.cover(cancel = root.coverRequestCanceled).await.resize(115, 115)
                this.image =
                  if cover == nil: emptyCover.parseSvg(115, 115).newImage
                  else: cover
              except RequestCanceled:
                echo "cancel"
                discard
            )(root, this, e)

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
      x.playlist[] = personalPlaylists().waitFor[0].playlist
      
      let styl = makeStyle(false, false)
      x.recieve(StyleChanged(fullStyle: styl, style: styl.window))
      
      x
  )
