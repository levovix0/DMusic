{.used.}
import sequtils, strutils, async, base64, strformat, os, sugar, tables
import qt, yandexMusic, config, cacheTable

const
  emptyCover = "qrc:resources/player/no-cover.svg"

var coverCache: CacheTable[(string, int), string]
onMainLoop: coverCache.garbageCollect


proc coverBase64(t: Track|Playlist, client: Client, quality = 1000): Future[string] {.async.} =
  ## download cover and encode it to base64
  coverCache[(t.coverUri, quality)] = client.request(t.coverUrl(quality)).await
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

proc search(query: string): Future[seq[Track]] {.async.} =
  let client = newClient(token=getToken())
  result = client.search(query).await.tracks

proc getCover(track: Track): Future[string] {.async.} =
  let client = newClient(token=getToken())
  return await track.coverBase64(client, 50)

const searchModelMaxLen = 5

qmodel SearchModel:
  rows: self.result.len.min(searchModelMaxLen)

  elem objId:      self.result[i].id
  elem objName:    self.result[i].title
  elem objComment: self.result[i].comment
  elem objCover:   self.covers[i]
  elem objArtist:  self.result[i].artists.mapit(it.name).join(", ")
  elem objKind:    "track"

  proc search(query: string) =
    cancel self.process
    self.process = @[]
    
    self.process.add: doAsync:
      self.result = search(query).await{0..<searchModelMaxLen}
      self.covers = sequtils.repeat(emptyCover, self.result.len)
      this.layoutChanged

      for i, track in self.result: capture i, track:
        self.process.add: doAsync:
          self.covers[i] = await getCover(track)
          this.layoutChanged

registerInQml SearchModel, "YandexMusic", 1, 0



var searchHistory: seq[string]
if fileExists(dataDir / "searchHistory.txt"):
  searchHistory = readFile(dataDir / "searchHistory.txt").splitLines[0..<5].filterit(it != "")

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
    writeFile(dataDir / "searchHistory.txt", searchHistory.join("\n"))
    this.layoutChanged

registerInQml SearchHistory, "DMusic", 1, 0  #TODO: singleton



type HomePlaylistsModel = object
  result: seq[Playlist]
  covers: seq[string]
  process: seq[Future[void]]

proc getHomePlaylists: Future[seq[Playlist]] {.async.} =
  let client = newClient(token=getToken())
  result = client.personalPlaylists.await.mapit(it.playlist)
  result.insert Playlist(
    id: 3,
    title: "Favorites"
  )

proc getCover(playlist: Playlist): Future[string] {.async.} =
  let client = newClient(token=getToken())
  return
    if playlist.id == 3: "qrc:/resources/covers/favorite.svg"
    else: await playlist.coverBase64(client, 400)

qmodel HomePlaylistsModel:
  rows: self.result.len

  elem objId:      self.result[i].id
  elem objTitle:   self.result[i].title
  elem objCover:   self.covers[i]

  proc load =
    cancel self.process
  
    self.process.add: doAsync:
      self.result = await getHomePlaylists()
      self.covers = sequtils.repeat(emptyCover, self.result.len)
      this.layoutChanged

      for i, playlist in self.result: capture i, playlist:
        self.process.add: doAsync:
          self.covers[i] = await getCover(playlist)
          this.layoutChanged

registerInQml HomePlaylistsModel, "YandexMusic", 1, 0
