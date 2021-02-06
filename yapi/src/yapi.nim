import nimpy, tables, strformat, uri, strutils

type 
  ErrorCode {.pure, size: cint.sizeof.} = enum
    ok = 0
    unknown = 1
    timeout = 2
  IdNotExist = object of CatchableError
  Id = distinct uint64

proc `==`(a, b: Id): bool {.borrow.}

var data: Table[Id, PyObject]

proc `[]`(a: Id): PyObject =
  if data.hasKey a: data[a]
  else: raise IdNotExist.newException("")


proc newId[T](a: Table[Id, T]): Id =
  var i = 0
  while a.hasKey Id i:
    inc i
  return Id i


let client = pyImport("yandex_music.client")
let logging = pyImport("logging")

discard logging.basicConfig(level=logging.ERROR) # отключает логи

var me: PyObject

# скачать трек https://music.yandex.ru/album/13527355/track/76601026
# discard me.tracks("76601026:13527355")[0].download("example.mp3")

# for a in me.users_likes_tracks():
#   let a = a.track
#   let filename = &"{a.id.to(string)}-{a.title.to(string)}"
#   discard a.download(&"out/{filename}.mp3")
#   discard a.downloadCover(&"out/{filename}-cover.png")



proc generate_token*(login, password: cstring): cstring {.stdcall, exportc, dynlib.} =
  try:
    let me = client.Client.from_credentials($login, $password)
    return me.token.to(string)
  except: return ""

proc login*(token: cstring): ErrorCode {.stdcall, exportc, dynlib.} =
  try:
    me = client.Client.from_token($token)
  except: return ErrorCode.unknown

proc track_from_id*(album, track: uint32): Id {.stdcall, exportc, dynlib.} =
  result = data.newId
  data[result] = me.tracks(&"{track}:{album}")[0]

proc track_from_link*(link: cstring): Id {.stdcall, exportc, dynlib.} =
  let link = link.`$`.parseUri.path.strip(chars={'/'}).split("/")
  track_from_id(link[1].parseInt.uint32, link[3].parseInt.uint32)

proc download_track*(track: Id, outPath: cstring): ErrorCode {.stdcall, exportc, dynlib.} =
  let track = track[]
  discard track.download($outPath)
