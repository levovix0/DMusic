import sequtils, strutils, asyncdispatch, base64, strformat, os, config
import qt, yandexMusic


template then(x: Future, body) =
  x.addCallback(proc(res: typeof(x)) =
    let res {.inject.} = read res
    body
  )

proc cancel(x: Future) =
  if x == nil or x.finished: return
  clearCallbacks x
  fail x, CatchableError.newException("Canceled")


proc coverBase64(client: Client, t: Track): Future[string] {.async.} =
  return &"data:image/png;base64,{client.request(t.coverUrl(50)).await.encode}"

proc search(query: string): Future[(seq[Track], seq[string])] {.async.} =
  var client = newClient()
  result[0] = client.search(query).await.tracks
  
  result[1].setLen result[0].len
  #TODO: parallel
  for i, track in result[0]:
    result[1][i] = await client.coverBase64(track)


type SearchModel = object
  result: seq[Track] #TODO: albums, artists
  covers: seq[string]
  process: Future[(seq[Track], seq[string])]

qmodel SearchModel:
  rows: self.result.len.min(5)

  elem objId:      self.result[i].id
  elem objName:    self.result[i].title
  elem objComment: self.result[i].comment
  elem objCover:   self.covers[i]
  elem objArtist:  self.result[i].artists.mapit(it.name).join(", ")
  elem objKind:    "track"

  proc search(query: string) =
    cancel self.process
    
    self.process = search(query)
    self.process.then:
      (self.result, self.covers) = res
      this.layoutChanged


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
    searchHistory = searchHistory[0..<5]
    writeFile(dataDir / "searchHistory.txt", searchHistory.join("\n"))
    this.layoutChanged


proc registerYandexMusicInQml* =
  registerInQml SearchModel, "YandexMusic", 1, 0
  registerInQml SearchHistory, "DMusic", 1, 0  #TODO: singleton
