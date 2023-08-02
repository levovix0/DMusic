import
  strformat, strutils, sequtils, options, os, times,
  json, uri, xmltree, xmlparser, checksums/md5, asyncdispatch, asyncfutures {.all.}
import httpclient except request
import ./[configuration, utils]
 
type
  HttpError* = object of CatchableError
  UnauthorizedError* = object of HttpError
  BadRequestError* = object of HttpError
  BadGatewayError* = object of HttpError
  RequestCanceled* = object of CatchableError

  ProgressReportCallback* = proc(total, progress, speed: BiggestInt): Future[void] {.gcsafe.}
  
  Client* = AsyncHttpClient

  TrackId* = object
    #TODO: user-added tracks
    id*: int
    # album*: int

  Track* = object
    id*: int
    # album*: int

    title*: string
    comment*: string
    coverUri*: string
    duration*: int ## in milliseconds
    explicit*: bool

    artists*: seq[Artist]
    albums*: seq[Album]
  
  Artist* = object
    id*: int

    name*: string
    coverUri*: string

  Album* = object
    id*: int

    title*: string
    coverUri*: string
    year*: int
    len*: int
  
  Playlist* = object
    id*: int
    uid*: int
    ownerId*: int

    title*: string
    description*: string
    coverUri*: string
    duration*: int ## in milliseconds
    len*: int

  RadioStation* = object
    id*: string
    stationFrom*: string
  
  Radio* = ref object
    station*: RadioStation
    batchId*: string
    tracksPassed*: seq[Track]
    tracks*: seq[Track]
    current*: Track
  
  Account* = object
    id*: int
    
    name*: string


proc `lang=`*(client: Client, lang: string) =
  client.headers["Accept-Language"] = lang

proc `token=`*(client: Client, token: string) =
  if token != "":
    client.headers["Authorization"] = &"OAuth {token}"

proc newClient*(config = config): Client =
  if config.proxyServer != "":
    result = newAsyncHttpClient("Yandex-Music-API", proxy=newProxy(config.proxyServer, config.proxyAuth))
  else:
    result = newAsyncHttpClient("Yandex-Music-API")
  result.headers["X-Yandex-Music-Client"] = "YandexMusicAndroid/23020251"
  result.token = config.ym_token
  result.lang = case config.language
    of ru: "ru"
    else: "en"


when defined(yandexMusic_oneRequestAtOnce):
  var requestLock: bool

proc request*(
  url: string|Uri,
  httpMethod: HttpMethod = HttpGet,
  body = "",
  data: MultipartData = nil,
  params: seq[(string, string)] = @[],
  progressReport: ProgressReportCallback = nil,
  cancel: ref bool = nil,
  ): Future[string] {.async.} =

  let url =
    if params.len == 0: $url
    else:
      when url is Uri: $(url ? params) else: $(url.parseUri ? params)

  logger.log(lvlInfo, &"Request: {url}") 

  let client = newClient()
  client.onProgressChanged = progressReport

  when defined(yandexMusic_oneRequestAtOnce):
    while requestLock:
      await sleepAsync(1)
    requestLock = true
  
  let response = await httpclient.request(client, url, httpMethod, body, nil, data)

  if cancel != nil and cancel[]:
    raise RequestCanceled.newException("request canceled, ingore it")

  when defined(yandexMusic_oneRequestAtOnce):
    requestLock = false

  template formatResponse: string =
    let body = response.body.await.parseJson
    if body{"error", "message"} != nil:
      response.status & ", " & body["error"]["message"].getStr
    else:
      response.status
  
  case response.code
  of Http200..Http206: return await response.body
  of Http400: raise BadRequestError.newException(formatResponse)
  of Http401, Http403: raise UnauthorizedError.newException(formatResponse)
  of Http502: raise BadGatewayError.newException(formatResponse)
  else: raise HttpError.newException(formatResponse)


proc asyncCheckOrCanceled*[T](f: Future[T]) =
  assert(not future.isNil, "Future is nil")
  proc callback =
    if f.failed and not(f.error of RequestCanceled):
      injectStacktrace(f)
      raise f.error
  f.callback = callback


iterator items(a: JsonNode): JsonNode =
  if a != nil and a.kind == JArray:
    for x in json.items(a):
      yield x


const
  baseUrl = "https://api.music.yandex.net"
  oauthUrl = "https://oauth.yandex.ru"


proc toInt(a: JsonNode): int =
  if a != nil and a.kind == JString:
    try: a.getStr.parseInt except: 0
  else: a.getInt


proc parseArtist*(a: JsonNode): Artist =
  result.id = a{"id"}.toInt

  result.name = a{"name"}.getStr
  result.coverUri = a{"cover", "uri"}.getStr

proc parseAlbum*(a: JsonNode): Album =
  result.id = a{"id"}.toInt

  result.title = a{"title"}.getStr
  result.coverUri = a{"coverUri"}.getStr
  result.year = a{"year"}.getInt
  result.len = a{"trackCount"}.getInt

proc parseTrackId*(a: JsonNode): TrackId =
  result.id = a{"id"}.toInt

proc parseTrack*(a: JsonNode): Track =
  result.id = a{"id"}.toInt

  result.title = a{"title"}.getStr
  result.comment = a{"version"}.getStr
  result.coverUri = a{"coverUri"}.getStr
  result.duration = a{"durationMs"}.getInt

  result.explicit = a{"explicit"}.getBool

  for album in a{"albums"}:
    result.albums.add album.parseAlbum
  
  for artist in a{"artists"}:
    result.artists.add artist.parseArtist
  
proc parsePlaylist*(a: JsonNode): Playlist =
  result.id = a{"kind"}.toInt
  result.uid = a{"uid"}.toInt
  result.ownerId = a{"owner", "uid"}.getInt

  result.title = a{"title"}.getStr
  result.description = a{"description"}.getStr
  result.coverUri = a{"cover", "uri"}.getStr
  result.duration = a{"durationMs"}.getInt
  result.len = a{"trackCount"}.getInt
  
proc parseAccount*(a: JsonNode): Account =
  result.id = a{"uid"}.toInt

  result.name = a{"displayName"}.getStr


proc generateToken*(username, password: string): Future[string] {.async.} =
  ## todo: remove
  return request(
    &"{oauthUrl}/token", HttpPost, data = newMultipartData {
      "grant_type": "password",
      "client_id": "23cabbbdc6cd418abb4b39c32c41195d",
      "client_secret": "53bc75238f0c4d08a118e51fe9203300",
      "username": username,
      "password": password,
    }
  ).await.parseJson["access_token"].getStr

proc search*(text: string, kind = "all", correct = true, cancel: ref bool = nil): Future[tuple[tracks: seq[Track]]] {.async.} =
  if text == "": return

  let response = request(
    &"{baseUrl}/search", cancel = cancel, params = @{
      "text": text,
      "nocorrect": $(not correct),
      "type": kind,
      "page": "0",
      # "playlist-in-best": "true",
    }
  ).await.parseJson

  for track in response{"result", "tracks", "results"}:
    result.tracks.add track.parseTrack
  #TODO: albums and artists


proc coverUrl*(this: Track|Album|Artist|Playlist, size = 1000): string =
  ## direct link to track's cover
  "https://" & this.coverUri.replace("%%", &"{size}x{size}")


proc `$`*(x: TrackId): string = $x.id

converter asId*(x: Track): TrackId = TrackId(id: x.id)
converter asId*(x: int): TrackId = TrackId(id: x)

converter asIdSeq*(x: TrackId): seq[TrackId] = @[x]
converter asIdSeq*(x: Track): seq[TrackId] = @[TrackId(id: x.id)]
converter asIdSeq*(x: int): seq[TrackId] = @[TrackId(id: x)]

proc parseTrackId*(s: string): TrackId =
  TrackId(id: s.parseInt)

proc fetch*(ids: seq[TrackId], withPositions = true, cancel: ref bool = nil): Future[seq[Track]] {.async.} =
  ## get full track information by ids
  if ids.len < 1: return
  
  let response = request(
    &"{baseUrl}/tracks", HttpPost, cancel = cancel, data = newMultipartData {
      "track-ids": ids.join(","),
      "with-positions": $withPositions
    }
  ).await.parseJson

  for res in response{"result"}:
    result.add res.parseTrack


proc audioUrl*(track: TrackId, cancel: ref bool = nil): Future[string] {.async.} =
  ## get direct link to track's audio
  ## ! works only one minute after call
  let response = request(
    &"{baseUrl}/tracks/{track.id}/download-info", cancel = cancel
  ).await

  let infoUrl = response.parseJson["result"][0]["downloadInfoUrl"].getStr

  # todo: check if link is direct
    
  let result = request(infoUrl, cancel = cancel).await.parseXml
  let host = result.findAll("host")[0].innerText
  let path = result.findAll("path")[0].innerText
  let ts = result.findAll("ts")[0].innerText
  let s = result.findAll("s")[0].innerText
  let sign = getMd5(&"XGRlBW9FXlekgbPrRHuSiA{path[1..^1]}{s}")
  let link = &"https://{host}/get-mp3/{sign}/{ts}{path}"
  
  logger.log(lvlInfo, "Builded link: ", link)
  return link


proc currentUser*(cancel: ref bool = nil): Future[Account] {.async.} =
  let response = request(
    &"{baseUrl}/account/status", cancel = cancel
  ).await.parseJson
  return response{"result", "account"}.parseAccount


proc likedTracks*(user: Account, cancel: ref bool = nil): Future[seq[TrackId]] {.async.} =
  ## get tracks that user liked
  let response = request(
    &"{baseUrl}/users/{user.id}/likes/tracks", cancel = cancel
  ).await.parseJson

  for track in response{"result", "library", "tracks"}:
    result.add track.parseTrackId
  
  result = result.filterit(it.id != 0)

proc dislikedTracks*(user: Account, cancel: ref bool = nil): Future[seq[TrackId]] {.async.} =
  ## get tracks that user liked
  let response = request(
    &"{baseUrl}/users/{user.id}/dislikes/tracks", cancel = cancel
  ).await.parseJson

  for track in response{"result", "library", "tracks"}:
    result.add track.parseTrackId
  
  result = result.filterit(it.id != 0)


proc liked*(user: Account, track: TrackId, cancel: ref bool = nil): Future[bool] {.async.} =
  return track in user.likedTracks(cancel = cancel).await

proc disliked*(user: Account, track: TrackId, cancel: ref bool = nil): Future[bool] {.async.} =
  return track in user.dislikedTracks(cancel = cancel).await


proc landing*(blocks: string): Future[JsonNode] {.async.} =
  ## get block
  ## ? requires token
  #TODO: seq of blocks
  return request(
    &"{baseUrl}/landing3", params = @{
      "blocks": blocks,
      "eitherUserId": "10254713668400548221"
    }
  ).await.parseJson

proc personalPlaylists*: Future[seq[tuple[kind: string, playlist: Playlist]]] {.async.} =
  ## get smart playlists for current user
  ## * requires token
  let response = await landing("personalplaylists")
  for Block in response{"result", "blocks"}:
    for entity in Block{"entities"}:
      result.add (entity{"data"}{"type"}.getStr, entity{"data"}{"data"}.parsePlaylist)


proc tracks*(playlist: Playlist): Future[seq[Track]] {.async.} =
  let response = request(
    &"{baseUrl}/users/{playlist.ownerId}/playlists/{playlist.id}"
  ).await.parseJson

  for track in response{"result", "tracks"}:
    result.add track{"track"}.parseTrack

proc playlist*(user: Account, id: int): Future[Playlist] {.async.} =
  let response = request(
    &"{baseUrl}/users/{user.id}/playlists/{id}"
  ).await.parseJson

  return response{"result"}.parsePlaylist


proc getRadioStation*(x: Track|TrackId): RadioStation =
  RadioStation(id: "track:" & $x.id, stationFrom: "track")


proc myWaveRadioStation*: RadioStation =
  RadioStation(id: "user:onyourwave", stationFrom: "user")


proc getTracks*(x: RadioStation, prev: Track = Track()): Future[tuple[tracks: seq[Track], batchId: string]] {.async.} =
  var params = @{
    "settings2": "true",
  }
  if prev.id != 0:
    params.add ("queue", $prev.id)
  let response = request(
    &"{baseUrl}/rotor/station/{x.id}/tracks", params=params
  ).await.parseJson
  result.batchId = response["result"]["batchId"].to(string)
  for track in response{"result", "sequence"}:
    if track{"type"}.to(string) == "track":
      result.tracks.add track{"track"}.parseTrack

proc sendFeedback(
  x: RadioStation,
  kind: string,
  track: Option[TrackId],
  batchId: string,
  totalPlayedSeconds: Option[int],
  time: DateTime = now()
) {.async.} =
  var data = %*{
    "type": kind,
    "from": x.stationFrom,
    "timestamp": time.toTime.toUnixFloat,
  }

  if track.isSome:
    data["trackId"] = newJString $track.get

  if totalPlayedSeconds.isSome:
    data["totalPlayedSeconds"] = newJString $totalPlayedSeconds.get

  try:
    discard request(
      &"{baseUrl}/rotor/station/{x.id}/feedback", HttpPost, body = $data, params = @{
        "batch-id": batchId,
      }
    ).await
  except:
    logger.log(lvlError, "feedback error: ", getCurrentExceptionMsg())

proc toRadio*(x: RadioStation, time: DateTime = now()): Future[Radio] {.async.} =
  new result
  result.station = x
  (result.tracks, result.batchId) = x.getTracks.await
  result.current = result.tracks[0]
  await x.sendFeedback("radioStarted", none TrackId, result.batchId, none int, time)

proc next*(x: Radio, totalPlayedSeconds: int, time: DateTime = now()): Future[Track] {.async.} =
  x.tracksPassed.add x.current
  await x.station.sendFeedback("trackFinished", some x.current.asId, x.batchId, some totalPlayedSeconds, time)
  (x.tracks, x.batchId) = x.station.getTracks(x.current).await
  x.current = x.tracks[0]  # todo: handle errors
  await x.station.sendFeedback("trackStarted", some x.current.asId, x.batchId, some totalPlayedSeconds, time)
  return x.current

proc skip*(x: Radio, totalPlayedSeconds: int, time: DateTime = now()): Future[Track] {.async.} =
  x.tracksPassed.add x.current
  await x.station.sendFeedback("skip", some x.current.asId, x.batchId, some totalPlayedSeconds, time)
  (x.tracks, x.batchId) = x.station.getTracks(x.current).await
  x.current = x.tracks[0]  # todo: handle errors
  await x.station.sendFeedback("trackStarted", some x.current.asId, x.batchId, some totalPlayedSeconds, time)
  return x.current


template trackLikeAction(name; url: string) {.dirty.} =
  proc name*(user: Account, ids: seq[TrackId]) {.async.} =
    if ids.len < 1: return

    discard request(
      &"{baseUrl}/users/{user.id}/" & url, HttpPost, data = newMultipartData {
        "track-ids": ids.join(",")
      }
    ).await

trackLikeAction like, "likes/tracks/add-multiple"
trackLikeAction unlike, "likes/tracks/remove"
trackLikeAction dislike, "dislikes/tracks/add-multiple"
trackLikeAction undislike, "dislikes/tracks/remove"


var coverCache*: CacheTable[(string, int), string]

proc cover*(track: Track, quality = 50, cancel: ref bool = nil): Future[string] {.async.} =
  {.cast(gcsafe).}:
    if (track.coverUri, quality) notin coverCache:
      coverCache[(track.coverUri, quality)] = request(track.coverUrl(quality), cancel = cancel).await
    return coverCache[(track.coverUri, quality)]

proc liked*(track: Track, cancel: ref bool = nil): Future[bool] {.async.} =
  return currentUser(cancel = cancel).await.liked(track, cancel = cancel).await

proc disliked*(track: Track, cancel: ref bool = nil): Future[bool] {.async.} =
  return currentUser(cancel = cancel).await.disliked(track, cancel = cancel).await


when isMainModule:
  let track = TrackId(id: 87086984).fetch.waitFor[0]
  let file = track.artists.mapit(it.name).join(", ") & " - " & track.title & ".mp3"
  writeFile file, request(track.audioUrl.waitFor).waitFor
