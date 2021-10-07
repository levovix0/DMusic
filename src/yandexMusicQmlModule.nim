import qt, yandexMusic

type YandexMusicTrack* = object
  track: Track


var client* = newClient()


proc id(this: YandexMusicTrack): int =
  this.track.id


qobject YandexMusicTrack of QObject:
  proc strid: int = id


proc registerYandexMusicInQml* =
  YandexMusicTrack.registerInQml("DMusic", 1, 0)
