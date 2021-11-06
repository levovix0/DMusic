{.used.}
import sequtils, strutils, options, times, math, random, algorithm
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
var notifyPositionChanged: proc() = proc() = discard
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
  QAudioOutput {.importcpp: "QAudioOutput", header: "QAudioOutput".} = object

  PlayerState = enum
    psStopped
    psPlaying
    psPaused

proc newQMediaPlayer: ptr QMediaPlayer {.importcpp: "new QMediaPlayer()", header: "QMediaPlayer".}
proc position(this: ptr QMediaPlayer): int {.importcpp: "#->position(@)", header: "QMediaPlayer".}
proc `position=`(this: ptr QMediaPlayer, v: int) {.importcpp: "#->setPosition(@)", header: "QMediaPlayer".}
proc `source=`(this: ptr QMediaPlayer, v: QUrl) {.importcpp: "#->setSource(@)", header: "QMediaPlayer".}
proc play(this: ptr QMediaPlayer) {.importcpp: "#->play()", header: "QMediaPlayer".}
proc stop(this: ptr QMediaPlayer) {.importcpp: "#->stop()", header: "QMediaPlayer".}
proc pause(this: ptr QMediaPlayer) {.importcpp: "#->pause()", header: "QMediaPlayer".}
proc state(this: ptr QMediaPlayer): PlayerState {.importcpp: "#->playbackState()", header: "QMediaPlayer".}
proc `audioOutput=`(this: ptr QMediaPlayer, v: ptr QAudioOutput) {.importcpp: "#->setAudioOutput(@)", header: "QMediaPlayer".}

proc newQAudioOutput: ptr QAudioOutput {.importcpp: "new QAudioOutput()", header: "QAudioOutput".}
proc `volume=`(this: ptr QAudioOutput, volume: float) {.importcpp: "#->setVolume(@)", header: "QAudioOutput".}
proc muted(this: ptr QAudioOutput): bool {.importcpp: "#->isMuted()", header: "QAudioOutput".}
proc `muted=`(this: ptr QAudioOutput, muted: bool) {.importcpp: "#->setMuted(@)", header: "QAudioOutput".}

var player = newQMediaPlayer()
var audioOutput = newQAudioOutput()
player.audioOutput = audioOutput

proc calcVolume(): float =
  pow(config.volume, 2)

audioOutput.volume = calcVolume()

proc notifyPositionChangedC {.exportc.} =
  notifyPositionChanged()

proc notifyStateChangedC {.exportc.} =
  notifyStateChanged()

proc notifyTrackEndedC {.exportc.} =
  notifyTrackEnded()

proc onMain =
  {.emit: """
  QObject::connect(`player`, &QMediaPlayer::positionChanged, []() { `notifyPositionChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::playbackStateChanged, []() { `notifyStateChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::mediaStatusChanged, [](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) `notifyTrackEndedC`();
  });
  """.}
onMain()

proc play*(track: Track) {.async.} =
  currentTrack = track
  await fetch currentTrack
  notifyTrackChanged()
  player.source = track.audio.await
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

proc progress*: float =
  if currentTrack.duration != 0: player.position / currentTrack.duration
  else: 0.0



type PlayingTrackInfo = object
  cover: string
  liked: bool
  process: seq[Future[void]]

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
      await play @[yandexTrack id]
  
  proc playYmPlaylist(id: int, owner: int) =
    cancel self.process
    self.process = doAsync:
      var tracks: seq[Track]
      if id == 3:
        tracks = currentUser().await.likedTracks.await.mapit(yandexTrack it)
        tracks.insert userTracks().filterit(it.liked.await)
      else:
        tracks = Playlist(id: id, ownerId: owner).tracks.await.mapit(yandexTrack it)
      await play(tracks, (id, owner))
  
  proc playUserTrack(id: int) =
    cancel self.process
    self.process = doAsync:
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
    get: audioOutput.muted
    set: audioOutput.muted = value; this.mutedChanged
    notify
  
  property float volume:
    get: config.volume
    set:
      config.volume = value
      audioOutput.volume = calcVolume()
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

