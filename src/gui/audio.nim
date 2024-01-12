{.used.}
import sequtils, strutils, options, times, math, random, algorithm, os
import ../api, ../utils, ../async, ../taglib
import qt, messages, configuration
import ../yandexMusic except Track, Radio, toRadio

{.experimental: "overloadableEnums".}

randomize()

type
  TrackSequence = ref object
    current: int
    yandexId: (int, int)
    case isRadio: bool
    of false:
      tracks: seq[Track]
      history: seq[int]
      shuffle, loop: bool
    of true:
      radio: Radio
      radioHistory: seq[Track]

var currentTrack* = Track()
var currentSequence = new TrackSequence

var notify_track_changed*: Notification
var notify_position_changed*: Notification
var notify_player_state_changed*: Notification
var notify_state_changed: Notification
var notify_track_ended: Notification
var notify_track_failed_to_load: Notification
var notify_lost_internet_connection: Notification

proc curr(x: TrackSequence): Track =
  try:
    if x.isRadio:
      if x.current < x.radioHistory.len:
        x.radioHistory[x.current]
      else:
        x.radio.current
    else:
      if x.shuffle: x.tracks[x.history[x.current]]
      else: x.tracks[x.current]
  except: Track()

proc next(x: TrackSequence, totalPlayedSeconds: int, skip=true): Future[Track] {.async.} =
  if x.isRadio:
    if x.current >= x.radioHistory.len:
      x.radioHistory.add x.radio.current
      if skip:
        x.radio.skip(totalPlayedSeconds).await
      else:
        x.radio.next(totalPlayedSeconds).await

      if config.ym_skipRadioDuplicates:
        let history = x.radioHistory.mapit(it.id)
        for i in 1..10:
          if x.radio.current.id in history:
            when defined(debugYandexMusicBehaviour):
              echo "[debugYandexMusicBehaviour] skip in radio: ", x.curr.id
            x.radio.skip(1).await

    inc x.current
    return x.curr
  else:
    if x.shuffle:
      if x.current > x.history.high: return Track()
      x.history.delete 0
      x.history.add:
        toSeq(0..x.tracks.high)
        .filterit(it notin x.history[^(x.tracks.len div 2)..^1])
        .sample
      return x.tracks[x.history[x.current]]
    else:
      inc x.current
      if x.current > x.tracks.high:
        if x.loop: x.current = 0
      if x.current notin 0..x.tracks.high:
        return Track()
      else:
        return x.tracks[x.current]

proc prev(x: TrackSequence): Track =
  if x.isRadio:
    if x.current < 1:
      return Track()
    dec x.current
    return x.curr
  else:
    if x.shuffle:
      if x.current > x.history.high: return Track()
      x.history.del x.history.high
      x.history.insert:
        toSeq(0..x.tracks.high)
        .filterit(it notin x.history[0..<(x.tracks.len div 2)])
        .sample
      return x.tracks[x.history[x.current]]
    else:
      dec x.current
      if x.current < 0:
        if x.loop: x.current = x.tracks.high
      if x.current notin 0..x.tracks.high:
        return Track()
      else:
        return x.tracks[x.current]

proc shuffle(x: TrackSequence, current = -1) =
  if x.shuffle == true: return
  x.shuffle = true
  if x.tracks.len == 0: return
  
  var
    h1 = toSeq(0..x.tracks.high)
    h2 = toSeq(0..x.tracks.high)
    current =
      if current in 0..x.tracks.high: current
      else: rand(x.tracks.high)
  
  shuffle h1
  if current in h1[^(x.tracks.len div 2)..^1]: reverse h1
  shuffle h2
  if current in h2[0..<(x.tracks.len div 2)]: reverse h1
  
  x.history = h1 & @[current] & h2
  x.current = x.tracks.len

proc unshuffle(x: TrackSequence, current = 0) =
  if x.shuffle == false: return
  x.shuffle = false
  
  x.history = @[]
  x.current = current

notifyShuffleChanged &= proc() =
  if config.shuffle:
    shuffle(currentSequence, currentSequence.current)
  else:
    try: unshuffle(currentSequence, currentSequence.history[currentSequence.current])
    except: discard

notifyLoopChanged &= proc() =
  currentSequence.loop = config.loop == LoopMode.playlist

notifyTrackChanged &= proc() =
  if currentTrack.kind == TrackKind.none:
    currentSequence = TrackSequence()



type
  QMediaPlayer {.importcpp: "QMediaPlayer", header: "QMediaPlayer".} = object

  PlayerState* = enum
    psStopped
    psPlaying
    psPaused

proc newQMediaPlayer*: ptr QMediaPlayer {.importcpp: "new QMediaPlayer()", header: "QMediaPlayer".}
proc `notifyInterval=`*(this: ptr QMediaPlayer, interval: int) {.importcpp: "#->setNotifyInterval(@)", header: "QMediaPlayer".}
proc volume*(this: ptr QMediaPlayer): int {.importcpp: "#->volume(@)", header: "QMediaPlayer".}
proc `volume=`*(this: ptr QMediaPlayer, v: int) {.importcpp: "#->setVolume(@)", header: "QMediaPlayer".}
proc position*(this: ptr QMediaPlayer): int {.importcpp: "#->position(@)", header: "QMediaPlayer".}
proc `position=`*(this: ptr QMediaPlayer, v: int) {.importcpp: "#->setPosition(@)", header: "QMediaPlayer".}
proc `media=`*(this: ptr QMediaPlayer, media: QUrl) {.importcpp: "#->setMedia({#})", header: "QMediaPlayer".}
proc play*(this: ptr QMediaPlayer) {.importcpp: "#->play()", header: "QMediaPlayer".}
proc stop*(this: ptr QMediaPlayer) {.importcpp: "#->stop()", header: "QMediaPlayer".}
proc pause*(this: ptr QMediaPlayer) {.importcpp: "#->pause()", header: "QMediaPlayer".}
proc muted*(this: ptr QMediaPlayer): bool {.importcpp: "#->isMuted()", header: "QMediaPlayer".}
proc `muted=`*(this: ptr QMediaPlayer, muted: bool) {.importcpp: "#->setMuted(@)", header: "QMediaPlayer".}
proc state*(this: ptr QMediaPlayer): PlayerState {.importcpp: "#->state()", header: "QMediaPlayer".}

var player* = newQMediaPlayer()
player.notifyInterval = 50

proc calcVolume(): int =
  let volume = config.volume
  if volume > 0: int(pow(config.volume, 2) * 100).max(1)
  else: 0

notifyVolumeChanged &= proc() =
  player.volume = calcVolume()

player.volume = calcVolume()

proc notifyPositionChangedC {.exportc.} =
  notifyPositionChanged()

proc notifyStateChangedC {.exportc.} =
  notifyStateChanged()

proc notifyTrackEndedC {.exportc.} =
  notifyTrackEnded()

proc notify_track_failed_to_load_c {.exportc.} =
  notify_track_failed_to_load()

proc notify_lost_internet_connection_c {.exportc.} =
  notify_lost_internet_connection()

proc notify_player_state_changed_c {.exportc.} =
  notify_player_state_changed()

proc onMain =
  {.emit: """
  QObject::connect(`player`, &QMediaPlayer::positionChanged, []() { `notifyPositionChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::stateChanged, []() { `notifyStateChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::mediaStatusChanged, [](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) `notifyTrackEndedC`();
  });
  QObject::connect(`player`, QOverload<QMediaPlayer::Error>::of(&QMediaPlayer::error), [](QMediaPlayer::Error error){
    if (error == QMediaPlayer::NetworkError) `notify_lost_internet_connection_c`();
    else `notify_track_failed_to_load_c`();
  });
  QObject::connect(`player`, &QMediaPlayer::stateChanged, [](QMediaPlayer::State state) { `notify_player_state_changed_c`(); });
  """.}
onMain()

proc play*(track: Track) {.async.} =
  currentTrack = track
  await fetch currentTrack
  notifyTrackChanged()
  player.media = track.audio.await
  player.play

proc play*(tracks: seq[Track], yandexId = (0, 0)) {.async.} =
  currentSequence = TrackSequence(isRadio: false, tracks: tracks, yandexId: yandexId)
  if config.shuffle: shuffle currentSequence
  currentSequence.loop = config.loop == LoopMode.playlist
  await play currentSequence.curr

proc play*(tracks: seq[Track], yandexId = (0, 0), trackToStartFrom: int) {.async.} =
  currentSequence = TrackSequence(isRadio: false, tracks: tracks, yandexId: yandexId, current: trackToStartFrom)
  if config.shuffle: shuffle currentSequence, trackToStartFrom
  currentSequence.loop = config.loop == LoopMode.playlist
  await play currentSequence.curr

proc play*(radio: Radio, yandexId = (0, 0)) {.async.} =
  currentSequence = TrackSequence(isRadio: true, radio: radio, yandexId: yandexId)
  await play currentSequence.curr


proc pause* =
  player.pause

proc play* =
  player.play

proc stop* =
  player.stop
  currentTrack = Track()
  notifyTrackChanged()

var getTrackAudioProcess: Future[void]

proc next*(skip=true) =
  cancel getTrackAudioProcess  # todo: cancel it really
  getTrackAudioProcess = doAsync:
    await play currentSequence.next(if skip: player.position div 1000 else: currentTrack.duration div 1000, skip).await

proc prev* =
  if player.position > 10_000:
    player.position = 0
  else:
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      await play currentSequence.prev


proc progress*: float =
  if currentTrack.duration != 0: player.position / currentTrack.duration
  else: 0.0



type PlayingTrackInfo = object
  cover: string
  hqCover: string
  liked: bool
  disliked: bool
  hasLiked: bool
  process: seq[Future[void]]
  saveProcess: Future[void]
  saveProgress: float

qobject PlayingTrackInfo:
  property string title:
    get: currentTrack.title
    notify infoChanged

  property string artists:
    get: currentTrack.artists
    notify infoChanged

  property string comment:
    get: currentTrack.comment
    notify infoChanged

  property string duration:
    get:
      let ms = currentTrack.duration.ms
      if ms.inHours != 0: ms.format("h:m:ss")
      else:               ms.format("m:ss")
    notify infoChanged
  
  property string position:
    get:
      let ms = player.position.ms
      if ms.inHours != 0: ms.format("h:m:ss")
      else:               ms.format("m:ss")
    notify
  
  property float progress:
    get: progress()
    set: player.position = (value * currentTrack.duration.float).int
    notify positionChanged
  
  property int positionMs:
    get: player.position
    set: player.position = value
    notify positionChanged

  property bool liked:
    get: self.liked
    set:
      self.process.add: doAsync:
        await (currentTrack.liked = value)
      self.liked = value
      this.likedChanged
    notify
  
  property bool hasLiked:
    get: self.hasLiked
    notify likedChanged

  property string cover:
    get: self.cover
    notify

  property string hqCover:
    get:
      if self.hqCover == "":
        var instant = true
        self.process.add: doAsync:
          self.hqCover = currentTrack.hqCover.await
          if not instant:
            this.hqCoverChanged
        instant = false
      if self.hqCover != "": self.hqCover
      else: emptyCover
    notify

  property bool disliked:
    get: self.disliked
    set:
      self.process.add: doAsync:
        await (currentTrack.disliked = value)
      self.disliked = value
      this.dislikedChanged
    notify
  
  property string originalUrl:
    get:
      case currentTrack.kind
      of TrackKind.yandex: currentTrack.yandex.coverUrl
      else: ""
    notify coverChanged
  
  property int id:
    get:
      case currentTrack.kind
      of TrackKind.yandex: currentTrack.yandex.id
      of TrackKind.yandexIdOnly: currentTrack.yandexIdOnly.id
      of TrackKind.yandexFromFile:
        try: currentTrack.yandexFromFile.file.splitFile.name.parseInt
        except: 0
      else: 0
    notify infoChanged
  
  property int playlistId:
    get:
      currentSequence.yandexId[0]
    notify infoChanged
  
  property int playlistOwner:
    get:
      currentSequence.yandexId[1]
    notify infoChanged
  
  property bool canStartYandexRadio:
    get: currentTrack.kind in {TrackKind.yandex, TrackKind.yandexIdOnly, TrackKind.yandexFromFile}
    notify infoChanged

  proc `=new` =
    self.cover = emptyCover

    notifyTrackChanged &= proc() =
      cancel self.process
      
      wasMoved self
      self.cover = emptyCover
      self.hqCover = ""
      self.liked = false
      self.hasLiked = false
      self.disliked = false

      this.infoChanged
      this.coverChanged
      this.hqCoverChanged
      this.likedChanged
      this.dislikedChanged
      
      self.process.add: doAsync:
        self.cover = currentTrack.cover.await
        this.coverChanged
      
      self.process.add: doAsync:
        self.liked = currentTrack.liked.await
        self.hasLiked = true
        this.likedChanged
      
      self.process.add: doAsync:
        self.disliked = currentTrack.disliked.await
        this.dislikedChanged
      
      if config.ym_saveAllTracks:
        if self.saveProcess != nil: return
        self.saveProcess = doAsync:
          await currentTrack.save(progressReport = proc(total, progress, speed: BiggestInt) {.async.} =
            if total == 0: self.saveProgress = 0
            else: self.saveProgress = progress.int / total.int
            this.saveProgressChanged
          )
          self.saveProcess = nil
          self.saveProgress = 0
          this.infoChanged
          this.saveProgressChanged

    notifyPositionChanged &= proc() = this.positionChanged
  
  property bool saved:
    get: currentTrack.kind in {TrackKind.yandexFromFile, TrackKind.user}
    notify infoChanged
  
  property float saveProgress:
    get: self.saveProgress
    notify
  
  property string file:
    get: currentTrack.file
    notify infoChanged
  
  property string folder:
    get: currentTrack.file.splitPath.head
    notify infoChanged
  
  property bool isNone:
    get: currentTrack.kind == TrackKind.none
    notify infoChanged
  
  property string page:
    get: currentTrack.page
    notify infoChanged
  
  proc save =
    if self.saveProcess != nil: return
    self.saveProcess = doAsync:
      await currentTrack.save(progressReport = proc(total, progress, speed: BiggestInt) {.async.} =
        if total == 0: self.saveProgress = 0
        else: self.saveProgress = progress.int / total.int
        this.saveProgressChanged
      )
      self.saveProcess = nil
      self.saveProgress = 0
      this.infoChanged
      this.saveProgressChanged
  
  proc remove =
    self.process.add: doAsync:
      remove currentTrack
      await fetch currentTrack
      if currentTrack.kind == TrackKind.none: next()
      this.infoChanged

registerSingletonInQml PlayingTrackInfo, "DMusic", 1, 0


type AudioPlayer = object

qobject AudioPlayer:
  proc play = play()
  proc stop = stop()
  proc pause = pause()
  proc next = next()
  proc prev = prev()
  
  proc playYmTrack(id: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      await play @[yandexTrack id]
  
  proc playYmPlaylist(id: int, owner: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      var tracks: seq[Track]
      if id == 3:
        tracks = currentUser().await.likedTracks.await.mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      else:
        tracks = yandexMusic.Playlist(id: id, ownerId: owner).tracks.await.mapit(yandexTrack it)
      await play(tracks, (id, owner))
  
  proc playYmPlaylist(id: int, owner: int, trackToStartFrom: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      var tracks: seq[Track]
      if id == 3:
        tracks = currentUser().await.likedTracks.await.mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      else:
        tracks = yandexMusic.Playlist(id: id, ownerId: owner).tracks.await.mapit(yandexTrack it)
      await play(tracks, (id, owner), trackToStartFrom)
  
  proc playUserTrack(id: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      await play @[userTrack id]

  property bool shuffle:
    get: config.shuffle
    set: config.shuffle = value
    notify

  property int loop:
    get: config.loop.ord
    set: config.loop = value.LoopMode
    notify

  property bool muted:
    get: player.muted
    set: player.muted = value; this.mutedChanged
    notify
  
  property float volume:
    get: config.volume
    set: config.volume = value
    notify

  property bool playing:
    get: player.state == psPlaying
    notify stateChanged

  property bool paused:
    get: player.state == psPaused
    notify stateChanged
  
  proc playYmUserPlaylist(id: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      let owner = currentUser().await.id
      var tracks: seq[Track]
      if id == 3:
        tracks = currentUser().await.likedTracks.await.mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      else:
        tracks = yandexMusic.Playlist(id: id, ownerId: owner).tracks.await.mapit(yandexTrack it)
      await play(tracks, (id, owner))

  proc playDmPlaylist(id: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      case id
      of 1: await play(downloadedYandexTracks(), (1, 0))
      of 2: await play(myWaveRadioStation().toRadio.await, (2, 0))
      else: discard

  proc playDmPlaylist(id: int, trackToStartFrom: int) =
    cancel getTrackAudioProcess
    getTrackAudioProcess = doAsync:
      case id
      of 1: await play(downloadedYandexTracks(), (1, 0), trackToStartFrom)
      of 2: await play(myWaveRadioStation().toRadio.await, (2, 0))  # todo
      else: discard
  
  proc addUserTrack(file, cover, title, comment, artists: string) =
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
    writeTrackMetadata(filename, (title, comment, artists, coverdata, false, false, Duration.default))
  
  proc playRadioFromYmTrack(id: int) =
    asyncCheck: doAsync:
      await play id.yandexTrack.toRadio.await
  
  proc setTrackLiked(kind: string, id: int, v: bool) =
    case kind
    of "yandex", "yandexFromFile", "yandexIdOnly":
      asyncCheck: doAsync:
        (id.yandexTrack.liked = v).await
    else: sendError(tr"Unimplemented", tr"toglleLiked() unknown track kind: {kind}")
    
  proc `=new` =
    notifyStateChanged &= proc() = this.stateChanged
    notifyShuffleChanged &= proc() = this.shuffleChanged
    notifyLoopChanged &= proc() = this.loopChanged
    notifyTrackEnded &= proc() =
      # play next track or loop current if needed
      cancel getTrackAudioProcess
      getTrackAudioProcess = doAsync:
        if config.loop == LoopMode.track:
          await play currentTrack
        else:
          next(skip=false)
    
    notifyVolumeChanged &= proc() = this.volumeChanged
    notify_track_failed_to_load &= proc =
      next()
    
    notify_lost_internet_connection &= proc =
      pause()


registerSingletonInQml AudioPlayer, "DMusic", 1, 0

