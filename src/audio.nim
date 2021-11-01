{.used.}
import sequtils, strutils, options, times, math
import qt, configuration, yandexMusic, utils, yandexMusicQmlModule, async, messages


type
  TrackKind = enum
    tkNone
    tkYandex
    
  TrackInfo = object
    case kind: TrackKind
    of tkYandex:
      yandex: yandexMusic.Track
    else: discard

var currentTrack: TrackInfo

var notifyTrackChanged: proc() = proc() = discard
var notifyPositionChanged: proc() = proc() = discard
var notifyStateChanged: proc() = proc() = discard



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

proc onMain =
  {.emit: """
  QObject::connect(`player`, &QMediaPlayer::positionChanged, []() { `notifyPositionChangedC`(); });
  QObject::connect(`player`, &QMediaPlayer::stateChanged, []() { `notifyStateChangedC`(); });
  """.}
onMain()

proc play*(track: yandexMusic.Track) {.async.} =
  currentTrack = TrackInfo(kind: tkYandex, yandex: track)
  notifyTrackChanged()
  player.media = track.audioUrl.await
  player.play

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

    notifyPositionChanged &= proc() =
      this.positionChanged

registerInQml PlayingTrackInfo, "DMusic", 1, 0


type PlayerController = object

var process: Future[void]

var notifyShuffleChanged: proc() = proc() = discard
var notifyLoopChanged: proc() = proc() = discard
var notifyMutedChanged: proc() = proc() = discard
var notifyVolumeChanged: proc() = proc() = discard

qobject PlayerController:
  proc play = play()
  proc stop = stop()
  proc pause = pause()

  proc next = discard
  proc prev = discard
  
  proc playYmTrack(id: int) =
    cancel process
    process = doAsync:
      id.fetch.await[0].play.await

  property bool shuffle:
    get: config.shuffle
    set: config.shuffle = value; notifyShuffleChanged()
    notify

  property int loop:
    get: config.loop.ord
    set: config.loop = value.LoopMode; notifyLoopChanged()
    notify

  property bool muted:
    get: player.muted
    set: player.muted = value; notifyMutedChanged()
    notify
  
  property float volume:
    get: config.volume
    set:
      config.volume = value.max(0).min(1)
      player.volume = calcVolume()
      notifyVolumeChanged()
    notify

  property bool playing:
    get: player.state == psPlaying
    notify stateChanged

  property bool paused:
    get: player.state == psPaused
    notify stateChanged
    
  proc `=new` =
    notifyStateChanged   &= proc() = this.stateChanged
    notifyShuffleChanged &= proc() = this.shuffleChanged
    notifyLoopChanged    &= proc() = this.loopChanged
    notifyMutedChanged   &= proc() = this.mutedChanged
    notifyVolumeChanged  &= proc() = this.volumeChanged

registerInQml PlayerController, "DMusic", 1, 0

