{.used.}
import sequtils, times
import ../utils, ../api, ../async
import ../yandexMusic except Track
import qt, configuration

type PlaylistView = object
  playlist: api.Playlist
  covers: seq[tuple[data: string, fetched: bool]]

qmodel PlaylistView:
  rows: self.playlist.tracks[].len
  elem objTitle: self.playlist.tracks[i].title
  elem objComment: self.playlist.tracks[i].comment
  elem objAuthor: self.playlist.tracks[i].artists
  elem objI: i

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
