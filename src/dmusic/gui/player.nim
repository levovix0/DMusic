import asyncdispatch, times, sequtils, strutils, os, strformat
import pixie/fileformats/svg, siwin, fusion/matching
import ../[configuration, api, utils, audio, taglib]
import ../musicProviders/[yandexMusic, youtube, requests]
import ./[uibase, style, globalShortcut, mouseArea]

type
  PlayerButton* = ref object of UiIcon
    style: Property[Style]
    activated: Event[void]
    accent: Property[bool]
    available: Property[bool] = true.property

  Player* = ref object of Uiobj
    style*: Property[Style]
    currentTrack*: Property[api.Track]
    trackSequence*: TrackSequence
    coverRequestCanceled, audioRequestCanceled, playlistRequestCanceled: ref bool
    outAudioStream*: OutAudioStream


proc formatSeconds(secs: int): string =
  let ms = initDuration(seconds = secs)
  if ms.inHours != 0: ms.format("h:mm:ss")
  else:               ms.format("m:ss")


proc newPlayerButton(): PlayerButton =
  result = PlayerButton()
  result.makeLayout:
    - newUiMouseArea() as mouse:
      this.fill parent

      this.pressed.changed.connectTo this:
        if root.available[] and not e and this.hovered[]: root.activated.emit()

    this.binding color:
      if this.style[] != nil:
        if not this.available[]:
          if this.accent[]: this.style[].accentButton.unavailableColor
          else: this.style[].button.unavailableColor
        elif mouse.pressed[] and mouse.hovered[]:
          if this.accent[]: this.style[].accentButton.pressedColor
          else: this.style[].button.pressedColor
        elif mouse.hovered[]:
          if this.accent[]: this.style[].accentButton.hoverColor
          else: this.style[].button.hoverColor
        else:
          if this.accent[]: this.style[].accentButton.color
          else: this.style[].button.color
      else: color(0, 0, 0)


method recieve*(this: PlayerButton, signal: Signal) =
  case signal
  of of StyleChanged(style: @style):
    this.style[] = style
  procCall this.super.recieve(signal)


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


proc play*(player: Player, tracks: seq[api.Track], yandexId = (0, 0)) =
  player.trackSequence = TrackSequence(isRadio: false, tracks: tracks, yandexId: yandexId)
  initTrackSequence player.trackSequence
  player.currentTrack[] = player.trackSequence.curr

proc play*(player: Player, tracks: seq[api.Track], yandexId = (0, 0), trackToStartFrom: int) =
  player.trackSequence = TrackSequence(isRadio: false, tracks: tracks, yandexId: yandexId, current: trackToStartFrom)
  initTrackSequence player.trackSequence
  player.currentTrack[] = player.trackSequence.curr

proc play*(player: Player, radio: api.Radio, yandexId = (0, 0)) =
  player.trackSequence = TrackSequence(isRadio: true, radio: radio, yandexId: yandexId)
  initTrackSequence player.trackSequence
  player.currentTrack[] = player.trackSequence.curr


proc pause*(player: Player) =
  player.outAudioStream.state[] = paused

proc play*(player: Player) =
  player.outAudioStream.state[] = playing

proc stop*(player: Player) =
  player.currentTrack[] = nil
  player.trackSequence = nil

proc next*(player: Player, skip=true) =
  if player.trackSequence != nil:
    asyncCheck: (proc(player: Player, skip: bool) {.async.} =
      player.currentTrack[] = player.trackSequence.next(
        (
          if skip: (player.outAudioStream.duration[].inSeconds.float * player.outAudioStream.position[]).int
          else: player.outAudioStream.duration[].inSeconds
        ),
        skip
      ).await
    )(player, skip)

proc prev*(player: Player) =
  if player.trackSequence != nil:
    if (player.outAudioStream.duration[].inSeconds.float * player.outAudioStream.position[]).int > 10:
      player.outAudioStream.position[] = 0
    else:
      player.currentTrack[] = player.trackSequence.prev()


proc playYmTrack*(player: Player, id: int) =
  player.play(@[yandexTrack id])

proc playYmPlaylist*(player: Player, id: int, owner: int, trackToStartFrom: int = -1) =
  if player.playlistRequestCanceled != nil: player.playlistRequestCanceled[] = true
  player.playlistRequestCanceled = new bool
  
  asyncCheck: (proc(player: Player, id: int, owner: int) {.async.} =
    try:
      var tracks: seq[api.Track]
      
      if id == 3:
        tracks = currentUser(cancel = player.playlistRequestCanceled).await
          .likedTracks(cancel = player.playlistRequestCanceled).await
          .mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      
      else:
        tracks = yandexMusic.Playlist(id: id, ownerId: owner)
          .tracks(cancel = player.playlistRequestCanceled).await
          .mapit(yandexTrack it)
      
      if trackToStartFrom != -1:
        player.play(tracks, (id, owner), trackToStartFrom)
      else:
        player.play(tracks, (id, owner))
    
    except RequestCanceled: discard
  )(player, id, owner)

proc playUserTrack*(player: Player, id: int) =
  player.play(@[userTrack id])

proc playYmUserPlaylist*(player: Player, id: int) =
  if player.playlistRequestCanceled != nil: player.playlistRequestCanceled[] = true
  player.playlistRequestCanceled = new bool
  
  asyncCheck: (proc(player: Player, id: int) {.async.} =
    try:
      let owner = currentUser(cancel = player.playlistRequestCanceled).await.id
      var tracks: seq[api.Track]
      if id == 3:
        tracks = currentUser(cancel = player.playlistRequestCanceled).await
          .likedTracks(cancel = player.playlistRequestCanceled).await
          .mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      else:
        tracks = yandexMusic.Playlist(id: id, ownerId: owner)
          .tracks(cancel = player.playlistRequestCanceled).await
          .mapit(yandexTrack it)
      player.play(tracks, (id, owner))
    
    except RequestCanceled: discard
  )(player, id)

proc playDmPlaylist*(player: Player, id: int, trackToStartFrom: int = -1) =
  if player.playlistRequestCanceled != nil: player.playlistRequestCanceled[] = true
  case id
  of 1:
    if trackToStartFrom != -1:
      player.play(downloadedYandexTracks(), (1, 0), trackToStartFrom)
    else:
      player.play(downloadedYandexTracks(), (1, 0))
  of 2:
    player.playlistRequestCanceled = new bool
    asyncCheck: (proc(player: Player, id: int) {.async.} =
      try:
        player.play(api.toRadio(myWaveRadioStation(), cancel = player.playlistRequestCanceled).await, (2, 0))
      except RequestCanceled: discard
    )(player, id)
  else: discard

proc addUserTrack*(player: Player, file, cover, title, comment, artists: string) =
  proc unfile(file: string): string =
    when defined(windows):
      if file.startsWith("file:///"): file[8..^1] else: file
    else:
      if file.startsWith("file://"): file[7..^1] else: file
  createDir dataDir / "user"
  let filename = dataDir / "user" / ($(userTracks().mapit(try: it.file.splitFile.name.parseInt except: 0).max + 1) & ".mp3")
  copyFile file.unfile, filename
  let coverdata =
    if cover == "": ""
    elif cover.startsWith("file:"): readFile cover.unfile
    else: readFile cover
    # TODO: http: handling
  writeTrackMetadata(filename, TrackMetadata(title: title, comment: comment, artists: artists, cover: coverdata, liked: false, disliked: false, duration: Duration.default))

proc playRadioFromYmTrack*(player: Player, id: int) =
  if player.playlistRequestCanceled != nil: player.playlistRequestCanceled[] = true
  player.playlistRequestCanceled = new bool
  
  asyncCheck: (proc(player: Player, id: int) {.async.} =
    try:
      player.play id.yandexTrack.toRadio.await
    
    except RequestCanceled: discard
  )(player, id)

proc setTrackLiked*(player: Player, kind: string, id: int, v: bool) =
  case kind
  of "yandex", "yandexFromFile", "yandexIdOnly":
    asyncCheck: (proc(id: int) {.async.} =
      (id.yandexTrack.liked = v).await
    )(id)
  else: logger.log(lvlError, &"toglleLiked() called on unknown track kind: {kind}")


proc newPlayer*(): Player =
  result = Player()
  result.makeLayout:
    root.outAudioStream = newOutAudioStream()
    root.outAudioStream.binding volume: config.volume[]
    do: discard
    do: false

    proc playTrack(this: OutAudioStream, e: api.Track) =
      this.state[] = paused
      if root.audioRequestCanceled != nil: root.audioRequestCanceled[] = true
      if e == nil:
        root.stop()
        return

      case e.kind
      of yandexIdOnly, youtubeIdOnly:  # fetch track from id
        root.audioRequestCanceled = new bool
        asyncCheck: (proc(this: OutAudioStream, track: api.Track, root: Player) {.async.} =
          try:
            if root.currentTrack[].fetch.await:
              root.currentTrack.changed.emit(root.currentTrack[])
          except RequestCanceled:
            discard
        )(this, e, root)
      
      of none:
        root.stop()

      else:
        root.audioRequestCanceled = new bool
        asyncCheck: (proc(this: OutAudioStream, track: api.Track, root: Player) {.async.} =
          try:
            let audioUrl = track.audio.await
            if audioUrl.startsWith("file:"):
              let file = audioUrl[5..^1]
              let audio = file.readFile[file.getTrackAudioStartByte..^1]
              this.playTrackFromMemory(audio)
            else:
              let audio = ymRequest(audioUrl, cancel = root.audioRequestCanceled).await
              this.playTrackFromMemory(audio)
            this.state[] = playing
          except RequestCanceled:
            discard
        )(this, e, root)

    root.outAudioStream.atEnd.connectTo root:
      if config.loop[] == track:
        playTrack(this.outAudioStream, this.currentTrack[])
      else:
        this.next()

    root.currentTrack.changed.connectTo root.outAudioStream: root.outAudioStream.playTrack(e)


    - newUiRect():
      this.fill(parent)
      this.binding color: (if parent.style[] != nil: parent.style[].backgroundColor else: color(0, 0, 0))

      - newUiMouseArea() as playerLineMouseArea:
        this.h[] = 16
        this.binding w: parent.w[] / 2.7
        this.y[] = 42
        this.centerX = parent.center

        - UiRect() as playerLineBackground:
          this.h[] = 4
          this.fillHorizontal parent
          this.centerY = parent.center
          this.radius[] = 2
          this.binding color: (if root.style[] != nil: root.style[].itemBackground else: color(0, 0, 0))

          - UiRect() as playerLine:
            this.h[] = parent.h[]
            this.radius[] = 2
            this.binding color:
              if root.style[] != nil:
                if playerLineMouseArea.hovered[]: root.style[].accent
                else: root.style[].itemColor
              else: color(0, 0, 0)
            
            proc updatePosition(this: UiRect, root: Player, pos: Vec2) =
              root.outAudioStream.position[] = pos.posToLocal(parent).x / parent.w[]
            
            playerLineMouseArea.pressed.changed.connectTo this:
              if e: updatePosition(this, root, this.parentWindow.mouse.pos.vec2)
            
            playerLineMouseArea.mouseMove.connectTo this:
              if playerLineMouseArea.pressed[]:
                updatePosition(this, root, e.pos.vec2)

            this.binding w: parent.w[] * root.outAudioStream.position[]
          
          - UiRectShadow() as pointShadow:
            this.binding visibility: (if root.style[] != nil and root.style[].itemDropShadow and playerLineMouseArea.hovered[]: Visibility.visible else: Visibility.hidden)
            this.wh[] = vec2(18, 18)
            this.blurRadius[] = 3
            this.radius[] = 6
            this.color[] = color(0, 0, 0, 0.2)
            this.centerY = playerLine.center
            this.centerX = playerLine.right

          - UiRect():
            this.binding visibility: (if playerLineMouseArea.hovered[]: Visibility.visible else: Visibility.hidden)
            this.centerIn pointShadow
            this.wh[] = vec2(12, 12)
            this.radius[] = 6
            this.color[] = color(1, 1, 1)
      
      - newUiText() as currentTimeText:
        this.right = playerLineMouseArea.left(-14)
        this.centerY = playerLineMouseArea.center
        this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
        this.binding text: (root.outAudioStream.duration[].inSeconds.float * root.outAudioStream.position[]).int.formatSeconds
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 12
            f
          else: nil
      
      - newUiText() as durationText:
        this.left = playerLineMouseArea.right(14)
        this.centerY = playerLineMouseArea.center
        this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
        this.binding text: root.outAudioStream.duration[].inSeconds.formatSeconds
        this.binding font:
          if root.style[] != nil and root.style[].typeface != nil:
            let f = newFont(root.style[].typeface)
            f.size = 12
            f
          else: nil

      - newUiobj() as playerControls:
        this.centerX = parent.center
        this.y[] = 21

        - newPlayerButton() as play_pause:
          this.centerIn parent
          
          const playIcon = staticRead "../../../resources/player/play.svg"
          const pauseIcon = staticRead "../../../resources/player/pause.svg"
          this.bindingProc `image=`:
            case root.outAudioStream.state[]
            of playing: pauseIcon.parseSvg().newImage
            of paused: playIcon.parseSvg().newImage
          
          this.binding available: root.currentTrack[] != nil

          this.activated.connectTo root:
            root.outAudioStream.state[] = case root.outAudioStream.state[]
            of playing: paused
            of paused: playing

        - newPlayerButton() as next:
          this.centerY = parent.center
          this.centerX = parent.center(50)
          
          this.binding available: root.currentTrack[] != nil
          
          const iconFile = staticRead "../../../resources/player/next.svg"
          this.image = iconFile.parseSvg().newImage

          this.activated.connectTo this:
            root.next()

        - newPlayerButton() as prev:
          this.centerY = parent.center
          this.centerX = parent.center(-50)
          
          this.binding available: root.currentTrack[] != nil
          
          const iconFile = staticRead "../../../resources/player/prev.svg"
          this.image = iconFile.parseSvg().newImage
          
          this.activated.connectTo this:
            root.prev()

        - newPlayerButton() as shuffle:
          this.centerY = parent.center
          this.centerX = parent.center(-100)
          
          const iconFile = staticRead "../../../resources/player/shuffle.svg"
          this.image = iconFile.parseSvg().newImage

          this.binding accent: config.shuffle[]

          this.activated.connectTo this:
            config.shuffle[] = not config.shuffle[]
        
        - newPlayerButton() as loop:
          this.centerY = parent.center
          this.centerX = parent.center(100)
          
          const loopIcon = staticRead "../../../resources/player/loop-playlist.svg"
          const loopTrackIcon = staticRead "../../../resources/player/loop-track.svg"
          this.bindingProc `image=`:
            case config.loop[]
            of none, playlist: loopIcon.parseSvg().newImage
            of track: loopTrackIcon.parseSvg().newImage
          
          this.binding accent:
            case config.loop[]
            of playlist, track: true
            of none: false

          this.activated.connectTo this:
            config.loop[] = case config.loop[]
            of none: LoopMode.playlist
            of playlist: LoopMode.track
            of track: LoopMode.none

      - newUiMouseArea() as mouse:
        this.fillVertical parent
        this.left = parent.left
        this.right = currentTimeText.left(-5)

        - newUiClipRect():
          this.fill parent
          this.binding visibility: (if mouse.hovered[]: Visibility.hidden else: Visibility.visible)

          - newUiRect():
            this.fillVertical parent
            this.binding visibility: (if mouse.hovered[]: Visibility.visible else: Visibility.hidden)
            this.binding color: (if root.style[] != nil: root.style[].backgroundColor else: color(0, 0, 0))

            - newUiImage() as cover:
              this.centerY = parent.center
              this.w[] = 50
              this.h[] = 50
              this.left = parent.left(8)
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
          
            - newUiText() as title:
              this.bottom = parent.center(-2)
              this.left = cover.right(11)
              this.binding color: (if root.style[] != nil: root.style[].color else: color(0, 0, 0))
              this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].title else: "")
              this.binding font:
                if root.style[] != nil and root.style[].typeface != nil:
                  let f = newFont(root.style[].typeface)
                  f.size = 14
                  f
                else: nil
          
            - newUiText() as comment:
              this.bottom = parent.center(-2)
              this.left = title.right(5)
              this.binding color: (if root.style[] != nil: root.style[].color3 else: color(0, 0, 0))
              this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].comment else: "")
              this.binding font:
                if root.style[] != nil and root.style[].typeface != nil:
                  let f = newFont(root.style[].typeface)
                  f.size = 14
                  f
                else: nil
          
            - newUiText() as authors:
              this.top = parent.center(3)
              this.left = cover.right(11)
              this.binding color: (if root.style[] != nil: root.style[].color2 else: color(0, 0, 0))
              this.binding text: (if root.currentTrack[] != nil: root.currentTrack[].artists else: "")
              this.binding font:
                if root.style[] != nil and root.style[].typeface != nil:
                  let f = newFont(root.style[].typeface)
                  f.size = 12
                  f
                else: nil

            this.binding w: max(authors.x[] + authors.w[], comment.x[] + comment.w[]) + 5
    

    - newUiRect():
      this.fillHorizontal(parent)
      this.top = Anchor(obj: root, offsetFrom: start, offset: -1)
      this.h[] = 2
      this.binding color: (if parent.style[] != nil: parent.style[].borderColor else: color(0, 0, 0))
      this.binding visibility: (if parent.style[] != nil and parent.style[].borders: Visibility.visible else: Visibility.hidden)
      
    - globalShortcut({Key.space}):
      this.activated.connectTo root:
        root.outAudioStream.state[] = case root.outAudioStream.state[]
        of playing: paused
        of paused: playing
    
    - globalShortcut({Key.up}):
      this.activated.connectTo root:
        config.volume[] = (config.volume[] + 0.05).max(0).min(1)
    
    - globalShortcut({Key.down}):
      this.activated.connectTo root:
        config.volume[] = (config.volume[] - 0.05).max(0).min(1)
    
    - globalShortcut({Key.left}):
      this.activated.connectTo root:
        root.prev()

    - globalShortcut({Key.right}):
      this.activated.connectTo root:
        root.next()
    
    - globalShortcut({Key.lshift, Key.p}): # temporary
      this.activated.connectTo root:
        root.play(searchYoutube("yonkagor").waitFor.tracks.mapit(it.id.youtubeTrack))
    
    - globalShortcut({Key.p}): # temporary
      this.activated.connectTo root:
        root.playDmPlaylist(2)
