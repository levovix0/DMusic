{.used.}
import times, utils
import async, qt, api, yandexMusic

type PlaylistView = object
  playlist: api.Playlist

qmodel PlaylistView:
  rows: self.playlist.tracks[].len
  elem objTitle: self.playlist.tracks[i].title
  elem objComment: self.playlist.tracks[i].comment
  elem objAuthor: self.playlist.tracks[i].artists
  elem objCover: self.playlist.tracks[i].cover.waitFor
  elem objDuration:
    let ms = self.playlist.tracks[i].duration.ms
    if ms.inHours != 0: ms.format("h:m:ss")
    else:               ms.format("m:ss")
  elem objI: i

  property int id:
    get:
      if self.playlist.kind == PlaylistKind.yandex: self.playlist.yandex.info.id
      else: 0
    notify infoChanged

  property int ownerId:
    get:
      if self.playlist.kind == PlaylistKind.yandex: self.playlist.yandex.info.ownerId
      else: 0
    notify infoChanged
  
  proc initYandex(id, ownerId: int) =
    self.playlist = api.Playlist(kind: PlaylistKind.yandex, yandex: (yandexMusic.Playlist(id: id, ownerId: ownerId), @[]))
    asyncCheck: doAsync:
      await fetch self.playlist
      this.layoutChanged
      this.infoChanged

registerSingletonInQml PlaylistView, "DMusic", 1, 0
