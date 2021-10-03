{.used.}
import httpclient, strformat, asyncdispatch, json, uri

type
  Requset* = ref object
    headers: HttpHeaders
    httpc: AsyncHttpClient
  
  Client* = ref object
    request: Requset
    token: string


proc `lang=`*(this: Requset, lang: string) =
  this.headers["Accept-Language"] = lang

proc `token=`*(this: Requset, token: string) =
  this.headers["Authorization"] = &"OAuth {token}"

proc newRequest*(lang="ru"): Requset =
  new result
  result.httpc = newAsyncHttpClient()
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
  ): Future[AsyncResponse] {.async.} =

  let url =
    if params.len == 0: url
    else: $(url.parseUri ? params)

  return await this.httpc.request(url, httpMethod, body, this.headers, data)


const
  baseUrl = "https://api.music.yandex.net"
  oauthUrl = "https://oauth.yandex.ru"


proc generateToken*(this: Client, username, password: string): Future[string] {.async.} =
  return this.request.request(
    &"{oauthUrl}/token", HttpPost, data = newMultipartData {
      "grant_type": "password",
      "client_id": "23cabbbdc6cd418abb4b39c32c41195d",
      "client_secret": "53bc75238f0c4d08a118e51fe9203300",
      "username": username,
      "password": password,
    }
  ).await.body.await.parseJson["access_token"].getStr

proc search*(this: Client, text: string, kind = "all"): Future[string] {.async.} =
  return this.request.request(
    &"{baseUrl}/search", HttpGet, params = @{
      "text": text,
      # "nocorrect": "False",
      "type": kind,
      "page": "0",
      # "playlist-in-best": "True",
    }
  ).await.body.await
