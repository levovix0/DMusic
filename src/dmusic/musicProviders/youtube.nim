## access youtube search, and audio through yt-dlp program
## requires yt-dlp and ffmpeg installed in system to work

import strutils, os, times, osproc, strtabs, streams, sequtils, uri, asyncdispatch, asyncfutures {.all.}, asynchttpserver, tables, browsers, htmlparser
import json except items
import httpclient except request
import ../[configuration]
import ./requests


type
  TrackId* = distinct string

  Track* = object
    id*: TrackId
    title*: string
    channel*: string
    thumbnailUrl*: string
  

const
  ytdlpBin = "yt-dlp"
  baseUrl = "https://www.googleapis.com/".parseUri
  apiPath = "youtube/v3"

  oauthClientId = "578304444415-c50q1vkgqjl0qk94cmibindlvvdm434g.apps.googleusercontent.com"
  oauthApiKey = "AIzaSyDft-QggMm9uiNG2elh7tHmOruASN8i1-4"


proc `$`*(x: TrackId): string = x.string


proc execProcessAsync(
  command: string, workingDir: string = "", args: seq[string] = @[],
  env: StringTableRef = nil, options: set[ProcessOption] = {poStdErrToStdOut, poUsePath, poEvalCommand},
  cancel: ref bool = nil,
): Future[string] {.async.} =
    var p = startProcess(
      command, workingDir = workingDir, args = args, env = env, options = options
    )
    var outp = outputStream(p)
    result = ""
    var line: string
    while true:
      line = outp.readAll()
      if line != "":
        result.add(line)
      elif not running(p): break
      if cancel != nil and cancel[]:
        raise RequestCanceled.newException("request canceled, ingore it")
      await sleepAsync(1)
    close(p)


proc parseTrack*(a: JsonNode): Track =
  result.id = a{"id"}.getStr.TrackId
  result.title = a{"title"}.getStr
  result.channel = a{"channel"}.getStr
  result.thumbnailUrl = a{"thumbnail"}.getStr


proc fetch*(id: TrackId, cancel: ref bool = nil): Future[Track] {.async.} =
  createDir dataDir / "youtube-tmp"
  return execProcessAsync(
    ytdlpBin, dataDir/"youtube-tmp",
    @[
      "--dump-json",
      id.string,
    ],
    options={poStdErrToStdOut, poUsePath}, cancel=cancel
  ).await.parseJson.parseTrack


proc downloadAudio*(id: TrackId, file: string, cancel: ref bool = nil) {.async.} =
  createDir file.parentDir
  if fileExists file:
    removeFile file
  logger.log lvlInfo, "yt-dlp (download audio): " & execProcessAsync(
    ytdlpBin, file.parentDir,
    @[
      "-f", "m4a",
      "-x", "--audio-format", "mp3",
      "-o", file.splitFile.name & ".m4a",
      id.string,
    ],
    options={poStdErrToStdOut, poUsePath}, cancel=cancel
  ).await
  await sleepAsync 1000  # seems like process is not really ended even after we awaited it  # todo: fix


proc newYtClient*(): AsyncHttpClient =
  newAsyncHttpClient(
    headers = newHttpHeaders {
      "Authorization": "Bearer " & config.yt_token,
      "Content-Type": "application/json",
      "X-Goog-Request-Time": $getTime().toUnix
    }
  )

proc ytRequest*(
  url: string|Uri,
  httpMethod: HttpMethod = HttpGet,
  body = "",
  data: MultipartData = nil,
  params: seq[(string, string)] = @[],
  progressReport: ProgressReportCallback = nil,
  cancel: ref bool = nil,
  ): Future[string] {.async.} =
  await requests.request(newYtClient(), url, httpMethod, body, data, params, progressReport, cancel)


proc clearYmTmpDir* =
  removeDir dataDir / "youtube-tmp"
  createDir dataDir / "youtube-tmp"


var oauthForUserUrlTokenRes: string

proc oauthForUserUrl(): Future[tuple[url: Uri, token: Future[string]]] {.async.} =
  let server = newAsyncHttpServer()
  server.listen(Port 0)

  result.url = "https://accounts.google.com/o/oauth2/auth".parseUri ? {
    "client_id": oauthClientId,
    "redirect_uri": "http://127.0.0.1:" & $server.getPort.uint16,
    "response_type": "code",
    "scope": "https://www.googleapis.com/auth/youtube",
  }
  
  result.token = (proc(server: AsyncHttpServer): Future[string] {.async.} =  # listen for token
    oauthForUserUrlTokenRes = ""
    while true:
      try:
        if server.shouldAcceptRequest():
          await server.acceptRequest(proc(req: Request) {.async.} =
            let query = req.url.query.decodeQuery.toSeq.toTable          
            let headers = {"Content-type": "text/plain; charset=utf-8"}
            await req.respond(Http200, "OK", headers.newHttpHeaders())

            {.cast(gcsafe).}:
              if "code" in query:
                oauthForUserUrlTokenRes = query["code"]
                close server
          )
        else:
          await sleepAsync(500)
      except:
        return oauthForUserUrlTokenRes
  )(server)


proc youtubeAuthorizeProcess* {.async.} =
  ## note: listen to config.yt_token.changed to get when authorization is finished
  let (url, token) = oauthForUserUrl().await
  openDefaultBrowser $url
  config.yt_token[] = token.await


proc searchYoutube*(query: string, maxResults = 5, cancel: ref bool = nil): Future[tuple[tracks: seq[Track]]] {.async.} =
  let response = ytRequest(baseUrl/apiPath/"search", cancel=cancel,
    params = @{
      "key": oauthApiKey,
      "q": query,
      "part": "snippet",
      "maxResults": $maxResults,
      "topicId": "music",
      "type": "video",
    }
  ).await.parseJson

  proc htmlToUtf8(s: string): string =
    var i = 0
    while i < s.len:
      defer: inc i
      if s[i] == '&':
        inc i
        var s2 = ""
        while i < s.len and s[i] != ';':
          s2.add s[i]
          inc i
        result.add s2.entityToUtf8
      else:
        result.add s[i]

  for x in response{"items"}:
    if x{"id"}{"kind"}.getStr != "youtube#video": continue  # todo
    var track: Track
    track.id = x{"id"}{"videoId"}.getStr.TrackId
    track.title = x{"snippet"}{"title"}.getStr.htmlToUtf8
    track.channel = x{"snippet"}{"channelTitle"}.getStr.htmlToUtf8
    track.thumbnailUrl = x{"snippet"}{"thumbnails"}{"default"}{"url"}.getStr
    result.tracks.add track


when isMainModule:
  ##
  echo searchYoutube("levovix").waitFor
