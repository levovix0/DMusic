import sequtils, strutils
import impl
import qt, yandexMusic

var client* = newClient()


type YandexMusicTrack = object
  track: Track

impl YandexMusicTrack:
  proc id: int = this.track.id
  proc title: string = this.track.title
  proc comment: string = this.track.comment
  proc artists: string = this.track.artists.mapit(it.name).join(", ")
  proc cover: string = this.track.coverUrl
  proc isExplicit: bool = this.track.explicit

qobject YandexMusicTrack:
  proc idStr: int = id
  proc title: string
  proc comment: string
  proc artists: string
  proc cover: string
  proc isExplicit: bool


proc registerYandexMusicInQml* =
  YandexMusicTrack.registerInQml("DMusic", 1, 0)
