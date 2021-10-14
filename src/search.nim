{.used.}
import qt
import httpclient, strformat, json, uri

type
  Requset* = ref object
    headers: HttpHeaders
    httpc: HttpClient
  
  Client* = ref object
    request: Requset
    token: string
  


proc `lang=`*(this: Requset, lang: string) =
  this.headers["Accept-Language"] = lang

proc `token=`*(this: Requset, token: string) =
  this.headers["Authorization"] = &"OAuth {token}"

proc newRequest*(lang="ru"): Requset =
  new result
  result.httpc = newHttpClient()
  result.headers = newHttpHeaders()
  result.lang = lang
  result.headers["User-Agent"] = "Yandex-Music-API"


proc newClient*(): Client =
  new result
  result.request = newRequest()

proc newClient*(token: string): Client =
  result = newClient()
  result.token = token

proc request*(
  this: Requset,
  url: string,
  httpMethod: HttpMethod,
  body = "",
  data: MultipartData = nil,
  params: seq[(string, string)] = @[]
  ): Response =

  let url =
    if params.len == 0: url
    else: $(url.parseUri ? params)

  return this.httpc.request(url, httpMethod, body, this.headers, data)


const
  baseUrl = "https://api.music.yandex.net"
  oauthUrl = "https://oauth.yandex.ru"


proc generateToken*(this: Client, username, password: string): string =
  return this.request.request(
    &"{oauthUrl}/token", HttpPost, data = newMultipartData {
      "grant_type": "password",
      "client_id": "23cabbbdc6cd418abb4b39c32c41195d",
      "client_secret": "53bc75238f0c4d08a118e51fe9203300",
      "username": username,
      "password": password,
    }
  ).body.parseJson["access_token"].getStr

proc search*(this: Client, text: string, kind = "all"): string =
  return this.request.request(
    &"{baseUrl}/search", HttpGet, params = @{
      "text": text,
      # "nocorrect": "False",
      "type": kind,
      "page": "0",
      # "playlist-in-best": "True",
    }
  ).body


type
  StdFunction[Rerturn, Arg] {.importcpp: "std::function<'0('1)>", header: "<functional>".} = object

{.experimental: "callOperator".}
proc `()`[R, T](this: StdFunction[R, T], a: T): R {.importcpp: "#(#)".}


proc ym_search*(token: QString, text: QString, kind: QString): QString {.exportc.} =
  let x = newClient($token).search($text, $kind)
  result = x
