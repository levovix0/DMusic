{.used.}
import sequtils, strutils, options, times, math, random, algorithm, os
import qt, configuration, api, utils, async, messages
import yandexMusic except Track

randomize()

type
  TrackSequence = object
    tracks: seq[Track]
    yandexId: (int, int)
    history: seq[int]
    current: int
    shuffle, loop: bool

var currentTrack = Track()
var currentSequence: TrackSequence

var notifyTrackChanged: proc() = proc() = discard
var notifyPositionChanged*: proc() = proc() = discard
var notifyStateChanged: proc() = proc() = discard
var notifyTrackEnded: proc() = proc() = discard

proc curr(x: var TrackSequence): Track =
  try:
    if x.shuffle: x.tracks[x.history[x.current]]
    else: x.tracks[x.current]
  except: Track()

proc next(x: var TrackSequence): Track =
  if x.shuffle:
    if x.current > x.history.high: return Track()
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
    if x.current notin 0..x.tracks.high: Track()
    else: x.tracks[x.current]

proc prev(x: var TrackSequence): Track =
  if x.shuffle:
    if x.current > x.history.high: return Track()
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
    if x.current notin 0..x.tracks.high: Track()
    else: x.tracks[x.current]

proc shuffle(x: var TrackSequence, current = -1) =
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

proc onMain =
  {.emit: """
  QObject::connect(`player`, &QMediaPlayer::positionChanged, []() { `notifyPositionChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::stateChanged, []() { `notifyStateChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::mediaStatusChanged, [](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) `notifyTrackEndedC`();
  });
  """.}
onMain()

proc play*(track: Track) {.async.} =
  currentTrack = track
  await fetch currentTrack
  notifyTrackChanged()
  player.media = track.audio.await
  player.play

proc play*(tracks: seq[Track], yandexId = (0, 0)) {.async.} =
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
  currentTrack = Track()
  notifyTrackChanged()

var getTrackAudioProcess: Future[void]

proc next* =
  cancel getTrackAudioProcess
  getTrackAudioProcess = doAsync:
    await play currentSequence.next

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
  liked: bool
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

  property string cover:
    get: self.cover
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
      
      self.process.add: doAsync:
        self.cover = currentTrack.cover.await
        this.coverChanged
      
      self.process.add: doAsync:
        self.liked = currentTrack.liked.await
        this.likedChanged

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
        tracks = Playlist(id: id, ownerId: owner).tracks.await.mapit(yandexTrack it)
      await play(tracks, (id, owner))
  
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
          await play currentSequence.next
    
    notifyVolumeChanged &= proc() = this.volumeChanged

registerSingletonInQml AudioPlayer, "DMusic", 1, 0

