import httpclient, strformat, asyncdispatch, json, uri, xmltree, xmlparser, md5

type
  HttpError* = object of CatchableError
  UnauthorizedError* = object of HttpError
  BadRequestError* = object of HttpError
  BadGatewayError* = object of HttpError
  
  Client* = ref object
    headers: HttpHeaders
    httpc: AsyncHttpClient

  TrackId* = object
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


proc `lang=`*(this: Client, lang: string) =
  this.headers["Accept-Language"] = lang

proc `token=`*(this: Client, token: string) =
  this.headers["Authorization"] = &"OAuth {token}"

proc newClient*(lang="ru"): Client =
  new result
  result.httpc = newAsyncHttpClient()
  result.headers = newHttpHeaders()
  result.lang = lang
  result.headers["User-Agent"] = "Yandex-Music-API"

proc newClient*(token: string): Client =
  result = newClient()
  result.token = token

proc request*(
  this: Client,
  url: string,
  httpMethod: HttpMethod = HttpGet,
  body = "",
  data: MultipartData = nil,
  params: seq[(string, string)] = @[]
  ): Future[string] {.async.} =

  let url =
    if params.len == 0: url
    else: $(url.parseUri ? params)

  let response = await this.httpc.request(url, httpMethod, body, this.headers, data)
  case response.code
  of Http200..Http206: return await response.body
  of Http400: raise BadRequestError.newException(response.status)
  of Http401, Http403: raise UnauthorizedError.newException(response.status)
  of Http502: raise BadGatewayError.newException(response.status)
  else: raise HttpError.newException(response.status)


const
  baseUrl = "https://api.music.yandex.net"
  oauthUrl = "https://oauth.yandex.ru"


proc parseArtist*(a: JsonNode): Artist =
  result.id = a{"id"}.getInt

  result.name = a{"name"}.getStr
  result.coverUri = a{"cover", "uri"}.getStr

proc parseAlbum*(a: JsonNode): Album =
  result.id = a{"id"}.getInt

  result.title = a{"title"}.getStr
  result.coverUri = a{"coverUri"}.getStr
  result.year = a{"year"}.getInt
  result.len = a{"trackCount"}.getInt

proc parseTrack*(a: JsonNode): Track =
  result.id = a{"id"}.getInt

  result.title = a{"title"}.getStr
  result.comment = a{"version"}.getStr
  result.coverUri = a{"coverUri"}.getStr
  result.duration = a{"duration"}.getInt

  result.explicit = a{"explicit"}.getBool

  for album in a{"albums"}:
    result.albums.add album.parseAlbum
  
  for artist in a{"artists"}:
    result.artists.add artist.parseArtist


proc generateToken*(this: Client, username, password: string): Future[string] {.async.} =
  return this.request(
    &"{oauthUrl}/token", HttpPost, data = newMultipartData {
      "grant_type": "password",
      "client_id": "23cabbbdc6cd418abb4b39c32c41195d",
      "client_secret": "53bc75238f0c4d08a118e51fe9203300",
      "username": username,
      "password": password,
    }
  ).await.parseJson["access_token"].getStr

proc search*(this: Client, text: string, kind = "all", correct = true): Future[tuple[tracks: seq[Track]]] {.async.} =
  if text == "": return

  let response = this.request(
    &"{baseUrl}/search", params = @{
      "text": text,
      "nocorrect": $(not correct),
      "type": kind,
      "page": "0",
      # "playlist-in-best": "true",
    }
  ).await.parseJson

  if response{"result", "tracks", "results"} != nil:
    for track in response{"result", "tracks", "results"}:
      result.tracks.add track.parseTrack
  #TODO: albums and artists


proc coverUrl*(this: Track|Album|Artist, size = 1000): string =
  ## direct link to track's cover
  "https://" & this.coverUri.replace("%%", &"{size}x{size}")


proc `$`*(this: TrackId): string = $this.id


proc fetch*(this: Client, ids: TrackId|seq[TrackId], withPositions = true): Future[seq[Track]] {.async.} =
  ## get full track information by id
  when ids is seq[TrackId]:
    if ids.len < 1: return
  
  let response = this.request(
    &"{baseUrl}/tracks", HttpPost, data = newMultipartData {
      "track-ids": $ids,
      "with-positions": $withPositions
    }
  ).await.parseJson

  for res in response:
    result.add res.parseTrack

proc audioUrl*(this: Client, track: Track|TrackId): Future[string] {.async.} =
  ## get direct link to track's audio
  ##! works only one minute after call!
  let infoUrl = this.request(
    &"{baseUrl}/tracks/{track.id}/download-info"
  ).await.parseJson["downloadInfoUrl"].getString
    
  let result = await this.request(infoUrl).parseXml
  let host = result.findAll("host")[0].text
  let path = result.findAll("path")[0].text
  let ts = result.findAll("ts")[0].text
  let s = result.findAll("s")[0].text
  let sign = getMd5(&"XGRlBW9FXlekgbPrRHuSiA{path[1..^1]}{s}")
  
  return &"https://{host}/get-mp3/{sign}/{ts}{path}"

