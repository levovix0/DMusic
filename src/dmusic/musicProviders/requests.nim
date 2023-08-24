import
  strformat, strutils, options, os, times, htmlparser,
  json, uri, xmltree, checksums/md5, asyncdispatch, asyncfutures {.all.}
import httpclient except request
import ../[configuration, utils]

type
  HttpError* = object of CatchableError
  UnauthorizedError* = object of HttpError
  BadRequestError* = object of HttpError
  BadGatewayError* = object of HttpError
  RequestCanceled* = object of CatchableError

  ProgressReportCallback* = proc(total, progress, speed: BiggestInt): Future[void] {.gcsafe.}
  
  Client* = AsyncHttpClient


when defined(yandexMusic_oneRequestAtOnce):
  var requestLock: bool

proc request*(
  client: AsyncHttpClient,
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
    let body = response.body.await
    if body.startsWith("{"): # probably json, usualy from yandex
      try:
        let body = body.parseJson
        if body{"error", "message"} != nil:
          response.status & ", " & body["error"]["message"].getStr
        else:
          response.status

      except JsonParsingError:
        response.status & ", " & body
    
    elif body.startsWith("<"): # probably xml, usualy from google
      try:
        let body = body.parseHtml
        response.status & ", " & body[1][12].innerText
      
      except:
        response.status
    
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


iterator items*(a: JsonNode): JsonNode =
  if a != nil and a.kind == JArray:
    for x in json.items(a):
      yield x


proc toInt*(a: JsonNode): int =
  if a != nil and a.kind == JString:
    try: a.getStr.parseInt except: 0
  else: a.getInt