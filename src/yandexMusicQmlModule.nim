import sequtils, strutils, asyncdispatch, base64, strformat
import qt, yandexMusic

proc coverBase64(client: Client, t: Track): Future[string] {.async.} =
  return &"data:image/png;base64,{client.request(t.coverUrl(50)).await.encode}"


type YmSearchModel = object
  result: seq[Track] #TODO: albums, artists
  covers: seq[string]
  process: Future[(seq[Track], seq[string])]

proc search(query: string): Future[(seq[Track], seq[string])] {.async.} =
  var client = newClient()
  result[0] = client.search(query).await.tracks
  
  result[1].setLen result[0].len
  for i, track in result[0]:
    result[1][i] = await client.coverBase64(track)

template safeGet(x): auto =
  if i in 0..<this.result.len: x else: typeof(x).default

template then(x: Future, body) =
  x.addCallback(proc(res: typeof(x)) =
    let res {.inject.} = read res
    body
  )

qmodel YmSearchModel:
  rows: this.result.len.min(5)

  get objId:      safeGet cint this.result[i].id
  get objName:    safeGet toQString this.result[i].title
  get objComment: safeGet toQString this.result[i].comment
  get objCover:   safeGet toQString this.covers[i]
  get objArtist:  safeGet toQString this.result[i].artists.mapit(it.name).join(", ")
  get objKind:    safeGet toQString "track"

  proc search(query: string) =
    if this[].self.process != nil and not this[].self.process.finished:
      clearCallbacks this[].self.process
      fail this[].self.process, CatchableError.newException("No more needed")
    
    this[].self.process = search(query)
    this[].self.process.then:
      this[].self.result = res[0]
      this[].self.covers = res[1]
      this.layoutChanged


proc registerYandexMusicInQml* =
  registerInQml YmSearchModel, "YandexMusic", 1, 0, "SearchModel"
