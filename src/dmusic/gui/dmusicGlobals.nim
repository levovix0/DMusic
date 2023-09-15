import uibase, player
import ../api

type
  PlaylistEntryAction* = enum
    play
    pause

  PlaylistEntrySignal* = ref object of SubtreeSignal
    playlist*: Playlist
    action*: PlaylistEntryAction

var
  g_player*: Property[Player]

template whenNotNilDo*[T](prop: var Property[T], obj: HasEventHandler, body: untyped) =
  proc procUsedInside(e {.inject.}: T) =
    if e != nil:
      body
  if prop[] != nil:
    procUsedInside(prop[])
  connect prop.changed, obj.eventHandler, procUsedInside

