import asyncdispatch, strutils, sequtils, os, strformat, base64, times
import yandexMusicQmlModule, taglib, configuration, utils
import yandexMusic except Track

type
  TrackKind* {.pure.} = enum
    none
    yandex
    yandexFromFile
    yandexIdOnly
    user

  UserTrack* = tuple
    file: string
    metadata: TrackMetadata

  YandexFromFileTrack* = tuple
    file: string
    metadata: TrackMetadata
  
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


proc yandexTrack*(id: TrackId): Track =
  let filename = dataDir / "yandex" / &"{id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.yandexFromFile,
      yandexFromFile: (file: filename, metadata: readTrackMetadata(filename))
    )
  else:
    return Track(kind: TrackKind.yandexIdOnly, yandexIdOnly: id)

proc yandexTrack*(x: yandexMusic.Track): Track =
  let filename = dataDir / "yandex" / &"{x.id}.mp3"
  if fileExists filename:
    return Track(
      kind: TrackKind.yandexFromFile,
      yandexFromFile: (file: filename, metadata: readTrackMetadata(filename))
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

proc save*(this: Track, file: string, progressReport: ProgressReportCallback = nil) {.async.} =
  if this.kind == TrackKind.yandexIdOnly:
    await fetch this
  if this.kind == TrackKind.yandex:
    createDir file.splitPath.head
    let (title, comment, artists) = (this.yandex.title, this.yandex.comment, this.yandex.artists.mapit(it.name).join(", "))
    let (audio, cover, liked) = (
      this.yandex.audioUrl.await.request(progressReport=progressReport),
      this.yandex.coverUrl(1000).request,
      this.yandex.liked
    )
    writeFile file, audio.await
    writeTrackMetadata(file, title, comment, artists, cover.await, liked.await, writeCover=true)
    this[] = TrackObj(kind: TrackKind.yandexFromFile, yandexFromFile: (
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
    template x: untyped = this.yandexFromFile.metadata
    this.yandexFromFile.metadata.liked = v
    writeTrackMetadata(this.yandexFromFile.file, x.title, x.comment, x.artists, "", v, writeCover=false)
    ## TODO fetch and like
  of TrackKind.user:
    template x: untyped = this.user.metadata
    this.user.metadata.liked = v
    writeTrackMetadata(this.user.file, x.title, x.comment, x.artists, "", v, writeCover=false)
  else: discard

proc disliked*(this: Track): Future[bool] {.async.} =
  return case this.kind
  of TrackKind.yandex:
    this.yandex.disliked.await
  of TrackKind.yandexFromFile:
    # this.yandexFromFile.metadata.disliked
    false
  of TrackKind.user:
    # this.user.metadata.disliked
    false
  else: false

proc `disliked=`*(this: Track, v: bool) {.async.} =
  case this.kind
  of TrackKind.yandex:
    if v: currentUser().await.dislike(this.yandex).await
    else: currentUser().await.undislike(this.yandex).await
  of TrackKind.yandexFromFile:
    ## TODO fetch and dislike
  of TrackKind.user:
    ## TODO
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
