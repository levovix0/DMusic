import asyncdispatch, strutils, sequtils, os, strformat, base64, times
import gui/yandexMusicQmlModule, gui/configuration  # todo: refactor to not use anthing from gui
import taglib, utils
import yandexMusic except Track

{.experimental: "overloadableEnums".}

type
  TrackKind* = enum
    none
    yandex
    yandexFromFile
    yandexIdOnly
    user
  
  Track* = ref TrackObj
  TrackObj* = object
    case kind*: TrackKind
    of TrackKind.yandex:
      yandex*: yandexMusic.Track
    of TrackKind.yandexFromFile:
      yandexFromFile*: YandexFromFileTrack
    of TrackKind.yandexIdOnly:
      yandexIdOnly*: TrackId
    of TrackKind.user:
      user*: UserTrack
    else: discard

  UserTrack* = tuple
    file: string
    metadata: TrackMetadata

  YandexFromFileTrack* = tuple
    id: yandexMusic.TrackId
    file: string
    metadata: TrackMetadata
  

  PlaylistKind* = enum
    yandex
    user
    temporary
  
  Playlist* = ref PlaylistObj
  PlaylistObj* = object
    case kind*: PlaylistKind
    of PlaylistKind.yandex:
      yandex*: YandexPlaylist
    of PlaylistKind.user:
      user*: UserPlaylist
    of PlaylistKind.temporary:
      temporary*: TemporaryPlaylist
  
  YandexPlaylist* = tuple
    info: yandexMusic.Playlist
    tracks: seq[Track]
  
  UserPlaylist* = tuple
    name: string
    tracks: seq[Track]
    file: string
  
  TemporaryPlaylist* = tuple
    id: int
    tracks: seq[Track]
  
  RadioKind* = enum
    yandex
  
  Radio* = ref RadioObj
  RadioObj* = object
    case kind*: RadioKind
    of yandex:
      yandex*: yandexMusic.Radio


proc yandexTrack*(id: TrackId): Track =
  let filename = dataDir / "yandex" / &"{id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.yandexFromFile,
      yandexFromFile: (id: id, file: filename, metadata: readTrackMetadata(filename))
    )
  else:
    return Track(kind: TrackKind.yandexIdOnly, yandexIdOnly: id)

proc yandexTrack*(x: yandexMusic.Track): Track =
  let filename = dataDir / "yandex" / &"{x.id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.yandexFromFile,
      yandexFromFile: (id: x.asId, file: filename, metadata: readTrackMetadata(filename))
    )
  else:
    return Track(kind: TrackKind.yandex, yandex: x)

proc userTrack*(id: int): Track =
  let filename = dataDir / "user" / &"{id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.user,
      user: (file: filename, metadata: readTrackMetadata(filename))
    )
  else:
    return Track()


proc fetch*(this: Track) {.async.} =
  if this.kind == TrackKind.yandexIdOnly:
    let id = this.yandexIdOnly.id
    this[] = TrackObj(kind: TrackKind.yandex, yandex: id.fetch.await[0])


proc forceFetch*(this: Track) {.async.} =
  await fetch this
  if this.kind == TrackKind.yandexFromFile:
    try:
      let id = this.yandexFromFile.file.splitFile.name.parseInt
      this[] = TrackObj(kind: TrackKind.yandex, yandex: id.fetch.await[0])
    except: discard


proc save*(this: Track, file: string, progressReport: ProgressReportCallback = nil) {.async.} =
  if this.kind == TrackKind.yandexIdOnly:
    await fetch this
  if this.kind == TrackKind.yandex:
    createDir file.splitPath.head
    let (title, comment, artists) = (this.yandex.title, this.yandex.comment, this.yandex.artists.mapit(it.name).join(", "))
    let (audio, cover, liked, disliked) = (
      this.yandex.audioUrl.await.request(progressReport=progressReport),
      this.yandex.coverUrl(1000).request,
      this.yandex.liked,
      this.yandex.disliked
    )
    writeFile file, audio.await
    writeTrackMetadata(file, (title, comment, artists, cover.await, liked.await, disliked.await, Duration.default), writeCover=true)
    this[] = TrackObj(kind: TrackKind.yandexFromFile, yandexFromFile: (
      id: this.yandex.asId,
      file: file,
      metadata: readTrackMetadata(file)
    ))

proc save*(this: Track, progressReport: ProgressReportCallback = nil) {.async.} =
  if this.kind == TrackKind.yandex:
    await this.save(dataDir / "yandex" / &"{this.yandex.id}.mp3", progressReport=progressReport)
  elif this.kind == TrackKind.yandexIdOnly:
    await this.save(dataDir / "yandex" / &"{this.yandexIdOnly.id}.mp3", progressReport=progressReport)

proc remove*(this: Track) =
  if this.kind == TrackKind.yandexFromFile:
    try:
      removeFile this.yandexFromFile.file
      this[] = TrackObj(kind: TrackKind.yandexIdOnly, yandexIdOnly: this.yandexFromFile.file.splitFile.name.parseInt)
    except: this[] = TrackObj(kind: TrackKind.none)
  elif this.kind == TrackKind.user:
    removeFile this.user.file
    this[] = TrackObj(kind: TrackKind.none)


proc userTracks*: seq[Track] =
  let dir = dataDir / "user"
  for (kind, path) in walkDir(dir):
    if kind in {pcFile, pcLinkToFile} and path.endsWith(".mp3"):
      result.add Track(
        kind: TrackKind.user,
        user: (file: path, metadata: readTrackMetadata(path))
      )

proc downloadedYandexTracks*: seq[Track] =
  let dir = dataDir / "yandex"
  for (kind, path) in walkDir(dir):
    if kind in {pcFile, pcLinkToFile} and path.endsWith(".mp3"):
      result.add Track(
        kind: TrackKind.yandexFromFile,
        yandexFromFile: (id: path.splitFile.name.parseTrackId, file: path, metadata: readTrackMetadata(path))
      )


proc audio*(this: Track): Future[string] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.audioUrl.await
  of TrackKind.yandexFromFile:
    "file:" & this.yandexFromFile.file
  of TrackKind.user:
    "file:" & this.user.file
  else: ""

proc cover*(this: Track): Future[string] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    yandexMusicQmlModule.cover(this.yandex).await
  of TrackKind.yandexFromFile:
    if this.yandexFromFile.metadata.cover.encode == "": emptyCover
    else: "data:image/png;base64," & this.yandexFromFile.metadata.cover.encode
  of TrackKind.user:
    if this.user.metadata.cover.encode == "": emptyCover
    else: "data:image/png;base64," & this.user.metadata.cover.encode
  else: ""

proc coverImage*(this: Track): Future[string] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.coverUrl.request.await
  of TrackKind.yandexFromFile:
    if this.yandexFromFile.metadata.cover == "": emptyCover
    else: this.yandexFromFile.metadata.cover
  of TrackKind.user:
    if this.user.metadata.cover == "": emptyCover
    else: this.user.metadata.cover
  else: ""

proc hqCover*(this: Track): Future[string] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    yandexMusicQmlModule.cover(this.yandex, quality=1000).await
  of TrackKind.yandexFromFile:
    if this.yandexFromFile.metadata.cover.encode == "": emptyCover
    else: "data:image/png;base64," & this.yandexFromFile.metadata.cover.encode
  of TrackKind.user:
    if this.user.metadata.cover.encode == "": emptyCover
    else: "data:image/png;base64," & this.user.metadata.cover.encode
  else: ""

proc title*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.title
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.title
  of TrackKind.user:
    this.user.metadata.title
  else: ""

proc comment*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.comment
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.comment
  of TrackKind.user:
    this.user.metadata.comment
  else: ""

proc artists*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.artists.mapit(it.name).join(", ")
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.artists
  of TrackKind.user:
    this.user.metadata.artists
  else: ""

proc liked*(this: Track): Future[bool] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.liked.await
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.liked
  of TrackKind.user:
    this.user.metadata.liked
  else: false

proc `liked=`*(this: Track, v: bool) {.async.} =
  case this.kind
  of TrackKind.yandex:
    if v: currentUser().await.like(this.yandex).await
    else: currentUser().await.unlike(this.yandex).await
  
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.liked = v
    writeTrackMetadata(this.yandexFromFile.file, this.yandexFromFile.metadata, writeCover=false)
    
    # like real track
    let t = deepcopy this
    await forceFetch t
    if t.kind == TrackKind.yandex:
      if v: currentUser().await.like(t.yandex).await
      else: currentUser().await.unlike(t.yandex).await
  
  of TrackKind.user:
    this.user.metadata.liked = v
    writeTrackMetadata(this.user.file, this.user.metadata, writeCover=false)
  
  else: discard

proc disliked*(this: Track): Future[bool] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.disliked.await
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.disliked
  of TrackKind.user:
    this.user.metadata.disliked
  else: false

proc `disliked=`*(this: Track, v: bool) {.async.} =
  case this.kind
  of TrackKind.yandex:
    if v: currentUser().await.dislike(this.yandex).await
    else: currentUser().await.undislike(this.yandex).await
  
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.disliked = v
    writeTrackMetadata(this.yandexFromFile.file, this.yandexFromFile.metadata, writeCover=false)
    
    # dislike real track
    let t = deepcopy this
    await forceFetch t
    if t.kind == TrackKind.yandex:
      if v: currentUser().await.dislike(t.yandex).await
      else: currentUser().await.undislike(t.yandex).await
  
  of TrackKind.user:
    this.user.metadata.disliked = v
    writeTrackMetadata(this.user.file, this.user.metadata, writeCover=false)
  
  else: discard

proc duration*(this: Track): int =
  case this.kind
  of TrackKind.yandex:
    this.yandex.duration
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.duration.inMilliseconds.int
  of TrackKind.user:
    this.user.metadata.duration.inMilliseconds.int
  else: 0

proc file*(this: Track): string =
  case this.kind
  of TrackKind.yandexFromFile:
    "file:" & this.yandexFromFile.file.absolutePath
  of TrackKind.user:
    "file:" & this.user.file.absolutePath
  else: ""

proc page*(this: Track): string =
  case this.kind
  of TrackKind.yandex:
    "https://music.yandex.ru/track/" & $this.yandex.id
  of TrackKind.yandexFromFile:
    "https://music.yandex.ru/track/" & this.yandexFromFile.file.splitFile.name
  else: ""


proc id*(track: Track): int =
  case track.kind
  of yandex:
    track.yandex.id
  of yandexFromFile:
    track.yandexFromFile.id.id
  of yandexIdOnly:
    track.yandexIdOnly.id
  else: 0


proc fetch*(playlist: Playlist) {.async.} =
  case playlist.kind
  of PlaylistKind.yandex:
    playlist.yandex.tracks = playlist.yandex.info.tracks.await.mapit(it.yandexTrack)
  else: discard

proc tracks*(playlist: Playlist): ptr seq[Track] =
  case playlist.kind
  of PlaylistKind.yandex:
    playlist.yandex.tracks.addr
  of PlaylistKind.user:
    playlist.user.tracks.addr
  of PlaylistKind.temporary:
    playlist.temporary.tracks.addr


# todo: refactor all above to do not specifing enum type, like as in proc below
proc toRadio*(track: Track): Future[Radio] {.async.} =
  case track.kind
  of yandex:
    return Radio(kind: yandex, yandex: track.yandex.getRadioStation.toRadio.await)
  of yandexFromFile:
    return Radio(kind: yandex, yandex: track.yandexFromFile.id.getRadioStation.toRadio.await)
  of yandexIdOnly:
    return Radio(kind: yandex, yandex: track.yandexIdOnly.getRadioStation.toRadio.await)
  else:
    raise ValueError.newException("can't convert this track to radio")

proc next*(radio: Radio, totalPlayedSeconds: int) {.async.} =
  case radio.kind
  of yandex:
    discard radio.yandex.next(totalPlayedSeconds).await

proc skip*(radio: Radio, totalPlayedSeconds: int) {.async.} =
  case radio.kind
  of yandex:
    discard radio.yandex.skip(totalPlayedSeconds).await

proc current*(radio: Radio): Track =
  case radio.kind
  of yandex:
    radio.yandex.current.yandexTrack

proc nextTracks*(radio: Radio): Future[seq[Track]] {.async.} =
  case radio.kind
  of yandex:
    return radio.yandex.tracks[1..^1].mapit(it.yandexTrack)

proc prevTracks*(radio: Radio): Future[seq[Track]] {.async.} =
  ## note: unused
  case radio.kind
  of yandex:
    return radio.yandex.tracksPassed.mapit(it.yandexTrack)
