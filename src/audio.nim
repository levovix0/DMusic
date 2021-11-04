{.used.}
import sequtils, strutils, options, times, math, random, algorithm
import qt, configuration, yandexMusic, utils, yandexMusicQmlModule, async, messages

randomize()

type
  TrackKind = enum
    tkNone
    tkYandex
    
  TrackInfo = ref object
    case kind: TrackKind
    of tkYandex:
      yandex: yandexMusic.Track
    else: discard
  
  TrackSequence = object
    tracks: seq[TrackInfo]
    yandexId: (int, int)
    history: seq[int]
    current: int
    shuffle, loop: bool

var currentTrack = TrackInfo()
var currentSequence: TrackSequence

var notifyTrackChanged: proc() = proc() = discard
var notifyPositionChanged: proc() = proc() = discard
var notifyStateChanged: proc() = proc() = discard
var notifyTrackEnded: proc() = proc() = discard

converter toTrackInfo(x: yandexMusic.Track): TrackInfo =
  TrackInfo(kind: tkYandex, yandex: x)

proc curr(x: var TrackSequence): TrackInfo =
  try:
    if x.shuffle: x.tracks[x.history[x.current]]
    else: x.tracks[x.current]
  except: TrackInfo(kind: tkNone)

proc next(x: var TrackSequence): TrackInfo =
  if x.shuffle:
    if x.current > x.history.high: return TrackInfo(kind: tkNone)
    x.history.delete 0
    x.history.add:
      toSeq(0..x.tracks.high)
      .filterit(it notin x.history[^(x.tracks.len div 2)..^1])
      .sample
    x.tracks[x.history[x.current]]
  else:
    inc x.current
    if x.current > x.tracks.high:
      if x.loop: x.current = 0
    if x.current notin 0..x.tracks.high: TrackInfo(kind: tkNone)
    else: x.tracks[x.current]

proc prev(x: var TrackSequence): TrackInfo =
  if x.shuffle:
    if x.current > x.history.high: return TrackInfo(kind: tkNone)
    x.history.del x.history.high
    x.history.insert:
      toSeq(0..x.tracks.high)
      .filterit(it notin x.history[0..<(x.tracks.len div 2)])
      .sample
    x.tracks[x.history[x.current]]
  else:
    dec x.current
    if x.current < 0:
      if x.loop: x.current = x.tracks.high
    if x.current notin 0..x.tracks.high: TrackInfo(kind: tkNone)
    else: x.tracks[x.current]

proc shuffle(x: var TrackSequence, current = -1) =
  if x.shuffle == true: return
  x.shuffle = true
  
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

proc unshuffle(x: var TrackSequence, current = 0) =
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
  if currentTrack.kind == tkNone:
    currentSequence = TrackSequence()



type
  QMediaPlayer {.importcpp: "QMediaPlayer", header: "QMediaPlayer".} = object

  PlayerState = enum
    psStopped
    psPlaying
    psPaused

proc newQMediaPlayer: ptr QMediaPlayer {.importcpp: "new QMediaPlayer()", header: "QMediaPlayer".}
proc `notifyInterval=`(this: ptr QMediaPlayer, interval: int) {.importcpp: "#->setNotifyInterval(@)", header: "QMediaPlayer".}
proc `volume=`(this: ptr QMediaPlayer, volume: int) {.importcpp: "#->setVolume(@)", header: "QMediaPlayer".}
proc position(this: ptr QMediaPlayer): int {.importcpp: "#->position(@)", header: "QMediaPlayer".}
proc `position=`(this: ptr QMediaPlayer, v: int) {.importcpp: "#->setPosition(@)", header: "QMediaPlayer".}
proc `media=`(this: ptr QMediaPlayer, media: QUrl) {.importcpp: "#->setMedia({#})", header: "QMediaPlayer".}
proc play(this: ptr QMediaPlayer) {.importcpp: "#->play()", header: "QMediaPlayer".}
proc stop(this: ptr QMediaPlayer) {.importcpp: "#->stop()", header: "QMediaPlayer".}
proc pause(this: ptr QMediaPlayer) {.importcpp: "#->pause()", header: "QMediaPlayer".}
proc muted(this: ptr QMediaPlayer): bool {.importcpp: "#->isMuted()", header: "QMediaPlayer".}
proc `muted=`(this: ptr QMediaPlayer, muted: bool) {.importcpp: "#->setMuted(@)", header: "QMediaPlayer".}
proc state(this: ptr QMediaPlayer): PlayerState {.importcpp: "#->state()", header: "QMediaPlayer".}

var player = newQMediaPlayer()
player.notifyInterval = 50

proc calcVolume(): int =
  let volume = config.volume
  if volume > 0: int(pow(config.volume, 2) * 100).max(1)
  else: 0

player.volume = calcVolume()

proc notifyPositionChangedC {.exportc.} =
  notifyPositionChanged()

proc notifyStateChangedC {.exportc.} =
  notifyStateChanged()

proc notifyTrackEndedC {.exportc.} =
  notifyTrackEnded()

proc onMain =
  {.emit: """
  QObject::connect(`player`, &QMediaPlayer::positionChanged, []() { `notifyPositionChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::stateChanged, []() { `notifyStateChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::mediaStatusChanged, [](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) `notifyTrackEndedC`();
  });
  """.}
onMain()

proc play*(track: TrackInfo) {.async.} =
  currentTrack = track
  notifyTrackChanged()
  case currentTrack.kind
  of tkYandex:
    player.media = track.yandex.audioUrl.await
    player.play
  else: player.stop

proc play*(tracks: seq[TrackInfo], yandexId = (0, 0)) {.async.} =
  currentSequence = TrackSequence(tracks: tracks, yandexId: yandexId)
  if config.shuffle: shuffle currentSequence
  currentSequence.loop = config.loop == LoopMode.playlist
  await play currentSequence.curr


proc pause* =
  player.pause

proc play* =
  player.play

proc stop* =
  player.stop
  currentTrack = TrackInfo()
  notifyTrackChanged()

proc duration*: int =
  case currentTrack.kind
  of tkYandex: currentTrack.yandex.duration
  else: 0

proc progress*: float =
  let duration = duration()

  if duration != 0: player.position / duration
  else: 0.0



type PlayingTrackInfo = object
  cover: string
  liked: bool
  process: seq[Future[void]]

qobject PlayingTrackInfo:
  property string title:
    get:
      case currentTrack.kind
      of tkYandex: currentTrack.yandex.title
      else: ""
    notify infoChanged

  property string artists:
    get:
      case currentTrack.kind
      of tkYandex: currentTrack.yandex.artists.mapit(it.name).join(", ")
      else: ""
    notify infoChanged

  property string comment:
    get:
      case currentTrack.kind
      of tkYandex: currentTrack.yandex.comment
      else: ""
    notify infoChanged

  property string duration:
    get:
      let ms = duration().ms
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
    set: player.position = (value * duration().float).int
    notify positionChanged
  
  property int positionMs:
    get: player.position
    set: player.position = value
    notify positionChanged

  property bool liked:
    get: self.liked
    set:
      case currentTrack.kind
      of tkYandex:
        self.process.add: doAsync:
          if value:
            currentUser().await.like(currentTrack.yandex).await
          else:
            currentUser().await.unlike(currentTrack.yandex).await
        self.liked = value
        this.likedChanged
      else: discard
    notify

  property string cover:
    get: self.cover
    notify
  
  property string originalUrl:
    get:
      case currentTrack.kind
      of tkYandex: currentTrack.yandex.coverUrl
      else: ""
    notify coverChanged
  
  property int id:
    get:
      case currentTrack.kind
      of tkYandex: currentTrack.yandex.id
      else: 0
    notify infoChanged
  
  property int playlistId:
    get: currentSequence.yandexId[0]
    notify infoChanged
  
  property int playlistOwner:
    get: currentSequence.yandexId[1]
    notify infoChanged

  proc `=new` =
    self.cover = emptyCover

    notifyTrackChanged &= proc() =
      cancel self.process
      
      wasMoved self
      self.cover = emptyCover

      this.infoChanged
      this.coverChanged
      this.likedChanged
      
      case currentTrack.kind
      of tkYandex:
        self.process.add: doAsync:
          self.cover = currentTrack.yandex.cover.await
          this.coverChanged
        
        self.process.add: doAsync:
          self.liked = currentTrack.yandex.liked.await
          this.likedChanged
      else: discard

    notifyPositionChanged &= proc() = this.positionChanged

registerSingletonInQml PlayingTrackInfo, "DMusic", 1, 0


type AudioPlayer = object
  process: Future[void]

qobject AudioPlayer:
  proc play = play()
  proc stop = stop()
  proc pause = pause()

  proc next =
    cancel self.process
    self.process = doAsync:
      if config.loop == LoopMode.track:
        await play currentTrack
      else:
        await play currentSequence.next
  
  proc prev =
    if player.position > 10_000:
      player.position = 0
    
    else:
      cancel self.process
      self.process = doAsync:
        if config.loop == LoopMode.track:
          await play currentTrack
        else:
          await play currentSequence.prev
  
  proc playYmTrack(id: int) =
    cancel self.process
    self.process = doAsync:
      await play @[id.fetch.await[0].toTrackInfo]
  
  proc playYmPlaylist(id: int, owner: int) =
    cancel self.process
    self.process = doAsync:
      #TODO: user tracks if id==3
      await play(Playlist(id: id, ownerId: owner).tracks.await.map(toTrackInfo), (id, owner))

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
    set:
      config.volume = value
      player.volume = calcVolume()
      this.volumeChanged
    notify

  property bool playing:
    get: player.state == psPlaying
    notify stateChanged

  property bool paused:
    get: player.state == psPaused
    notify stateChanged
    
  proc `=new` =
    notifyStateChanged &= proc() = this.stateChanged
    notifyShuffleChanged &= proc() = this.shuffleChanged
    notifyLoopChanged &= proc() = this.loopChanged
    notifyTrackEnded &= proc() =
      cancel self.process
      self.process = doAsync:
        if config.loop == LoopMode.track:
          await play currentTrack
        else:
          await play currentSequence.next

registerSingletonInQml AudioPlayer, "DMusic", 1, 0

