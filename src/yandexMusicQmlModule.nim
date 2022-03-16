{.used.}
import sequtils, strutils, async, base64, strformat, os, sugar, tables
import qt, yandexMusic, configuration, utils, messages

var coverCache: CacheTable[(string, int), string]
onMainLoop: coverCache.garbageCollect


proc coverBase64(t: Track|Playlist, quality = 1000): Future[string] {.async.} =
  ## download cover and encode it to base64
  coverCache[(t.coverUri, quality)] = request(t.coverUrl(quality)).await
  return &"data:image/png;base64,{coverCache[(t.coverUri, quality)].encode}"

proc `{}`[T](x: seq[T], s: Slice[int]): seq[T] =
  ## safe slice a seq
  if x.len == 0: return
  let s = Slice[int](a: s.a.max(x.low).min(x.high), b: s.b.max(x.low).min(x.high))
  x[s]



type SearchModel = object
  result: seq[Track] #TODO: albums, artists
  covers: seq[string]
  process: seq[Future[void]]
  nothingFound: bool

proc search(query: string): Future[seq[Track]] {.async.} =
  result = yandexMusic.search(query).await.tracks

proc cover*(track: Track, quality = 50): Future[string] {.async.} =
  return track.coverBase64(quality).await

proc liked*(track: Track): Future[bool] {.async.} =
  return currentUser().await.liked(track).await

proc disliked*(track: Track): Future[bool] {.async.} =
  return currentUser().await.disliked(track).await

const searchModelMaxLen = 5

qmodel SearchModel:
  rows: self.result.len

  elem objId:      self.result[i].id
  elem objName:    self.result[i].title
  elem objComment: self.result[i].comment
  elem objCover:   self.covers[i]
  elem objArtist:  self.result[i].artists.mapit(it.name).join(", ")
  elem objKind:    "track"

  property bool nothingFound:
    get: self.nothingFound
    notify

  proc search(query: string) =
    cancel self.process
    self.process = @[]
    
    self.process.add: doAsync:
      self.result = search(query).await{0..<searchModelMaxLen}

      try:
        self.result.insert query.parseInt.fetch.await[0]
      except: discard

      self.nothingFound = self.result.len == 0
      this.nothingFoundChanged

      self.covers = sequtils.repeat(emptyCover, self.result.len)
      this.layoutChanged

      for i, track in self.result: capture i, track:
        self.process.add: doAsync:
          self.covers[i] = await track.cover
          this.layoutChanged

registerSingletonInQml SearchModel, "YandexMusic", 1, 0



var searchHistory: seq[string]
if fileExists(dataDir / "searchHistory.txt"):
  searchHistory = readFile(dataDir / "searchHistory.txt").splitLines{0..<5}.filterit(it != "")

type SearchHistory = object

qmodel SearchHistory:
  rows: searchHistory.len

  elem element: searchHistory[i]

  proc savePromit(text: string) =
    if text == "": return
    if text in searchHistory:
      searchHistory.delete searchHistory.find(text)
    searchHistory.insert text, 0
    searchHistory = searchHistory{0..<5}
    createDir dataDir
    writeFile(dataDir / "searchHistory.txt", searchHistory.join("\n"))
    this.layoutChanged

registerSingletonInQml SearchHistory, "DMusic", 1, 0



type HomePlaylistsModel = object
  result: seq[Playlist]
  covers: seq[string]
  process: seq[Future[void]]

proc getHomePlaylists: Future[seq[Playlist]] {.async.} =
  var x = personalPlaylists().await
  
  let daily = x.mapit(it.kind).find("playlistOfTheDay")
  if daily != -1: x.move daily, 0

  result = x.mapit(it.playlist)
  result.insert Playlist(
    id: 3,
    ownerId: currentUser().await.id,
    title: tr"Favorites"
  )

proc cover(playlist: Playlist): Future[string] {.async.} =
  return
    if playlist.id == 3: tr"qrc:/resources/covers/favorite.svg"
    else: playlist.coverBase64(400).await

qmodel HomePlaylistsModel:
  rows: self.result.len + 1

  elem objId:
    case i - self.result.high
    of 1: 1
    else: self.result[i].id

  elem objTitle:
    case i - self.result.high
    of 1: tr"Downloads"
    else: self.result[i].title

  elem objCover:
    case i - self.result.high
    of 1: tr"qrc:/resources/covers/downloads.svg"
    else: self.covers[i]

  elem objOwner:
    case i - self.result.high
    of 1: 0
    else: self.result[i].ownerId

  proc load =
    cancel self.process
  
    self.process.add: doAsync:
      self.result = await getHomePlaylists()
      self.covers = sequtils.repeat(emptyCover, self.result.len)
      this.layoutChanged

      for i, playlist in self.result: capture i, playlist:
        self.process.add: doAsync:
          self.covers[i] = await playlist.cover
          this.layoutChanged

registerSingletonInQml HomePlaylistsModel, "YandexMusic", 1, 0


type YClient = object
  process: seq[Future[void]]

qobject YClient:
  proc login(email, password: string) =
    cancel self.process

    self.process.add: doAsync:
      try:
        config.ym_token = generateToken(email, password).await
        config.ym_email = email
      except:
        sendError tr"Failed to login", getCurrentExceptionMsg()

registerSingletonInQml YClient, "YandexMusic", 1, 0
