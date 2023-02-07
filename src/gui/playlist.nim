{.used.}
import sequtils, times
import ../utils, ../api, ../async
import ../yandexMusic except Track
import qt, configuration

{.experimental: "overloadableEnums".}

type PlaylistView = object
  playlist: api.Playlist
  covers: seq[tuple[data: string, fetched: bool]]
  liked: tuple[data: seq[bool]; fetched: bool]


qmodel PlaylistView:
  rows: self.playlist.tracks[].len
  elem objTitle: self.playlist.tracks[i].title
  elem objComment: self.playlist.tracks[i].comment
  elem objAuthor: self.playlist.tracks[i].artists
  elem objI: i
  elem objId: self.playlist.tracks[i].id
  elem objKind: $self.playlist.tracks[i].kind

  elem objCover:
    var instant = true
    if not self.covers[i].fetched:
      self.covers[i].fetched = true
      let track = self.playlist.tracks[i]
      asyncCheck: doAsync:
        self.covers[i].data = await track.cover
        if not instant: this.layoutChanged
    instant = false

    self.covers[i].data
      
  elem objDuration:
    let ms = self.playlist.tracks[i].duration.ms
    if ms.inHours != 0: ms.format("h:m:ss")
    else:               ms.format("m:ss")
  
  elem objLiked:
    if self.liked.fetched:
      if i in 0..self.liked.data.high:
        self.liked.data[i]
      else:
        false
    else:
      self.liked.fetched = true
      asyncCheck: doAsync:
        self.liked.data = self.playlist.liked.await
        this.layoutChanged
      false


  property int id:
    get:
      if self.playlist.kind == PlaylistKind.yandex: self.playlist.yandex.info.id
      elif self.playlist.kind == PlaylistKind.temporary: self.playlist.temporary.id
      else: 0
    notify infoChanged

  property int ownerId:
    get:
      if self.playlist.kind == PlaylistKind.yandex: self.playlist.yandex.info.ownerId
      else: 0
    notify infoChanged
  
  proc init(id, ownerId: int) =
    if id == 1 and ownerId == 0:
      self.playlist = api.Playlist(kind: PlaylistKind.temporary, temporary: (1, downloadedYandexTracks()))
    else:
      self.playlist = api.Playlist(kind: PlaylistKind.yandex, yandex: (yandexMusic.Playlist(id: id, ownerId: ownerId), @[]))
    asyncCheck: doAsync:
      await fetch self.playlist
      self.covers = sequtils.repeat((emptyCover, false), self.playlist.tracks[].len)
      this.infoChanged
      this.layoutChanged

registerSingletonInQml PlaylistView, "DMusic", 1, 0
