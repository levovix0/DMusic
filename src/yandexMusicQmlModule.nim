import sequtils, strutils, asyncdispatch, base64, strformat, locks
import impl
import qt, yandexMusic

proc coverBase64(client: Client, t: Track): Future[string] {.async.} =
  return &"data:image/png;base64,{client.request(t.coverUrl).await.encode}"


type YmSearchModel = object
  result: seq[Track] #TODO: albums, artists
  covers: seq[string]
  process: Future[(seq[Track], seq[string])]
  lock: Lock

impl YmSearchModel:
  proc search(query: string): Future[(seq[Track], seq[string])] {.mut, async.} =
    var client = newClient()
    result[0] = client.search(query).await.tracks
    
    result[1].setLen result[0].len
    for i, track in result[0]:
      result[1][i] = await client.coverBase64(track)

template safeGet(x): auto =
  block:
    var r: typeof(x)
    withLock this.lock:
      r = if i in 0..<this.result.len: x else: typeof(x).default
    r

qmodel YmSearchModel:
  rows: this.result.len.min(5)

  get objId:      safeGet cint this.result[i].id
  get objName:    safeGet toQString this.result[i].title
  get objComment: safeGet toQString this.result[i].comment
  get objCover:   safeGet toQString this.covers[i]
  get objArtist:  safeGet toQString this.result[i].artists.mapit(it.name).join(", ")
  get objKind:    safeGet toQString "track"

  proc init =
    initLock this[].self.lock

  proc search(query: string) =
    if this[].self.process != nil:
      if not this[].self.process.finished:
        clearCallbacks this[].self.process
    
    this[].self.process = this[].self.search(query)
    this[].self.process.addCallback(proc(f: Future[(seq[Track], seq[string])]) =
      withLock this[].self.lock:
        this[].self.result = f.read[0]
        this[].self.covers = f.read[1]
      this.layoutChanged
    )


proc registerYandexMusicInQml* =
  registerInQml YmSearchModel, "YandexMusic", 1, 0, "SearchModel"
