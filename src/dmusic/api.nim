import asyncdispatch, strutils, sequtils, os, strformat, times, pixie, pixie/fileformats/svg
import ./[configuration, taglib, utils]
import ./musicProviders/[yandexMusic, youtube, requests]

export RequestCanceled

{.experimental: "overloadableEnums".}

type
  TrackKind* = enum
    none

    yandex
    yandexFromFile
    yandexIdOnly
    
    youtubeTrack
    youtubeIdOnly
    youtubeFromFile
    
    user
  
  Track* = ref TrackObj
  TrackObj* = object
    case kind*: TrackKind
    of TrackKind.yandex:
      yandex*: yandexMusic.Track
    of TrackKind.yandexFromFile:
      yandexFromFile*: YandexFromFileTrack
    of TrackKind.yandexIdOnly:
      yandexIdOnly*: yandexMusic.TrackId
    
    of TrackKind.youtubeTrack:
      youtubeTrack*: youtube.Track
    of TrackKind.youtubeIdOnly:
      youtubeIdOnly*: youtube.TrackId
    of TrackKind.youtubeFromFile:
      youtubeFromFile*: YoutubeFromFileTrack

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
  
  YoutubeFromFileTrack* = tuple
    id: youtube.TrackId
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


proc yandexTrack*(id: yandexMusic.TrackId): Track =
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

proc youtubeTrack*(id: youtube.TrackId): Track =
  let filename = dataDir / "youtube" / &"{id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.youtubeFromFile,
      # youtubeFromFile: (id: id, file: filename, metadata: readTrackMetadata(filename))
      youtubeFromFile: (id: id, file: filename, metadata: TrackMetadata())
    )
  else:
    return Track(kind: TrackKind.youtubeIdOnly, youtubeIdOnly: id)


proc fetch*(this: Track, cancel: ref bool = nil): Future[bool] {.async.} =
  if this.kind == TrackKind.yandexIdOnly:
    this[] = TrackObj(
      kind: TrackKind.yandex,
      yandex: this.yandexIdOnly.id.fetch(cancel=cancel).await[0]
    )
    return true
  elif this.kind == TrackKind.youtubeIdOnly:
    this[] = TrackObj(
      kind: TrackKind.youtubeTrack,
      youtubeTrack: this.youtubeIdOnly.fetch(cancel=cancel).await
    )
    return true


proc forceFetch*(this: Track): Future[bool] {.async.} =
  result = await fetch this
  if this.kind == TrackKind.yandexFromFile:
    try:
      let id = this.yandexFromFile.file.splitFile.name.parseInt
      this[] = TrackObj(kind: TrackKind.yandex, yandex: id.fetch.await[0])
      return true
    except: discard
  elif this.kind == TrackKind.youtubeFromFile:
    this[] = TrackObj(kind: TrackKind.youtubeTrack, youtubeTrack: this.youtubeFromFile.id.fetch.await)
    return true


proc save*(this: Track, file: string, progressReport: ProgressReportCallback = nil, cancel: ref bool = nil) {.async.} =
  if this.kind in {TrackKind.yandexIdOnly, TrackKind.youtubeIdOnly}:
    discard await fetch this

  if this.kind == TrackKind.yandex:
    createDir file.splitPath.head
    let (title, comment, artists) = (this.yandex.title, this.yandex.comment, this.yandex.artists.mapit(it.name).join(", "))
    let (audio, cover, liked, disliked) = (
      this.yandex.audioUrl.await.ymRequest(progressReport=progressReport, cancel=cancel),
      this.yandex.coverUrl(1000).ymRequest(cancel=cancel),
      this.yandex.liked(cancel=cancel),
      this.yandex.disliked(cancel=cancel),
    )
    writeFile file, audio.await
    writeTrackMetadata(file, TrackMetadata(
      title: title,
      comment: comment,
      artists: artists,
      cover: cover.await,
      liked: liked.await,
      disliked: disliked.await,
      duration: Duration.default,
    ), writeCover=true)

    this[] = TrackObj(kind: TrackKind.yandexFromFile, yandexFromFile: (
      id: this.yandex.asId,
      file: file,
      metadata: readTrackMetadata(file)
    ))
  
  elif this.kind == TrackKind.youtubeTrack:
    createDir file.splitPath.head
    let (title, comment, artists) = (this.youtubeTrack.title, "", this.youtubeTrack.channel)
    let (cover, liked, disliked) = (
      this.youtubeTrack.thumbnailUrl.ytRequest,
      false,
      false,
    )
    
    this.youtubeTrack.id.downloadAudio(file, cancel=cancel).await
    
    writeTrackMetadata(file, TrackMetadata(
      title: title,
      comment: comment,
      artists: artists,
      cover: cover.await,
      liked: liked,
      disliked: disliked,
      duration: Duration.default,
    ), writeCover=true)

    this[] = TrackObj(kind: TrackKind.youtubeFromFile, youtubeFromFile: (
      id: this.youtubeTrack.id,
      file: file,
      metadata: readTrackMetadata(file)
    ))

proc save*(this: Track, progressReport: ProgressReportCallback = nil, cancel: ref bool = nil) {.async.} =
  if this.kind == TrackKind.yandex:
    await this.save(dataDir / "yandex" / &"{this.yandex.id}.mp3", progressReport=progressReport, cancel=cancel)
  elif this.kind == TrackKind.yandexIdOnly:
    await this.save(dataDir / "yandex" / &"{this.yandexIdOnly.id}.mp3", progressReport=progressReport, cancel=cancel)
  elif this.kind == TrackKind.youtubeTrack:
    await this.save(dataDir / "youtube" / &"{this.youtubeTrack.id}.mp3", progressReport=progressReport, cancel=cancel)
  elif this.kind == TrackKind.youtubeIdOnly:
    await this.save(dataDir / "youtube" / &"{this.youtubeIdOnly}.mp3", progressReport=progressReport, cancel=cancel)
  

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
  of TrackKind.youtubeTrack:
    this.youtubeTrack.id.downloadAudio(dataDir / "youtube-tmp" / "audio.mp3").await
    "file:" & dataDir / "youtube-tmp" / "audio.mp3"
  of TrackKind.youtubeFromFile:
    "file:" & this.youtubeFromFile.file
  else: ""

const
  lowQualityCover* = 50
  highQualityCover* = 1000

proc cover*(this: Track, quality = lowQualityCover, cancel: ref bool = nil): Future[pixie.Image] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    yandexMusic.cover(this.yandex, quality=quality, cancel=cancel).await.decodeImage.resize(quality, quality)

  of TrackKind.yandexFromFile:
    if this.yandexFromFile.metadata.cover == "": emptyCover.parseSvg(quality, quality).newImage
    else: this.yandexFromFile.metadata.cover.decodeImage.resize(quality, quality)

  of TrackKind.user:
    if this.user.metadata.cover == "": emptyCover.parseSvg(quality, quality).newImage
    else: this.user.metadata.cover.decodeImage.resize(quality, quality)

  of TrackKind.youtubeTrack:
    this.youtubeTrack.thumbnailUrl.ytRequest(cancel=cancel).await.decodeImage.resize(quality, quality)

  of TrackKind.youtubeFromFile:
    if this.youtubeFromFile.metadata.cover == "": emptyCover.parseSvg(quality, quality).newImage
    else: this.youtubeFromFile.metadata.cover.decodeImage.resize(quality, quality)

  else: emptyCover.parseSvg(50, 50).newImage

proc title*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.title
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.title
  of TrackKind.user:
    this.user.metadata.title
  of TrackKind.youtubeTrack:
    this.youtubeTrack.title
  of TrackKind.youtubeFromFile:
    this.youtubeFromFile.metadata.title
  else: ""

proc comment*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.comment
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.comment
  of TrackKind.user:
    this.user.metadata.comment
  of TrackKind.youtubeTrack, TrackKind.youtubeFromFile:
    ""
  else: ""

proc artists*(this: Track): string =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.artists.mapit(it.name).join(", ")
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.artists
  of TrackKind.user:
    this.user.metadata.artists
  of TrackKind.youtubeTrack:
    this.youtubeTrack.channel
  of TrackKind.youtubeFromFile:
    this.youtubeFromFile.metadata.artists
  else: ""

proc liked*(this: Track): Future[bool] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.liked.await
  of TrackKind.yandexFromFile:
    this.yandexFromFile.metadata.liked
  of TrackKind.user:
    this.user.metadata.liked
  of TrackKind.youtubeTrack, TrackKind.youtubeFromFile:
    false
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
    discard await forceFetch t
    if t.kind == TrackKind.yandex:
      if v: currentUser().await.like(t.yandex).await
      else: currentUser().await.unlike(t.yandex).await
  
  of TrackKind.yandexIdOnly:
    if v: currentUser().await.like(this.yandexIdOnly).await
    else: currentUser().await.unlike(this.yandexIdOnly).await
  
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
    discard await forceFetch t
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


converter toApi*(playlist: yandexMusic.Playlist): Playlist =
  Playlist(kind: PlaylistKind.yandex, yandex: (info: playlist, tracks: @[]))


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

proc liked*(playlist: Playlist): Future[seq[bool]] {.async.} =
  case playlist.kind
  of yandex:
    let liked = currentUser().await.likedTracks.await
    for x in playlist.yandex.tracks:
      result.add x.id in liked
  of user:
    for x in playlist.user.tracks:
      result.add x.liked.await
  of temporary:
    for x in playlist.temporary.tracks:
      result.add x.liked.await


proc title*(playlist: Playlist): string =
  case playlist.kind
  of PlaylistKind.yandex:
    playlist.yandex.info.title
  of PlaylistKind.user:
    playlist.user.name
  of PlaylistKind.temporary:
    ""

proc cover*(playlist: Playlist, quality = 400, cancel: ref bool = nil): Future[pixie.Image] {.async.} =
  return case playlist.kind
  of PlaylistKind.yandex:
    playlist.yandex.info.cover(quality, cancel).await.decodeImage
  of PlaylistKind.user: nil
  of PlaylistKind.temporary: nil


# todo: refactor all above to do not specifing enum type, like as in proc below
proc toRadio*(track: Track, cancel: ref bool = nil): Future[Radio] {.async.} =
  case track.kind
  of yandex:
    return Radio(kind: yandex, yandex: yandexMusic.toRadio(track.yandex.getRadioStation, cancel=cancel).await)
  of yandexFromFile:
    return Radio(kind: yandex, yandex: yandexMusic.toRadio(track.yandexFromFile.id.getRadioStation, cancel=cancel).await)
  of yandexIdOnly:
    return Radio(kind: yandex, yandex: yandexMusic.toRadio(track.yandexIdOnly.getRadioStation, cancel=cancel).await)
  else:
    raise ValueError.newException("can't convert this track to radio")

proc toRadio*(station: RadioStation, cancel: ref bool = nil): Future[Radio] {.async.} =
  return Radio(kind: yandex, yandex: yandexMusic.toRadio(station, cancel=cancel).await)

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
