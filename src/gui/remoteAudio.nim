{.used.}
import options, strformat, times
import discord_rpc
import ../utils, ../api
import audio, configuration

when defined(linux):
  import math
  import ../utils
  import qt, audio, configuration
  
  {.emit: """
  #include <QDBusConnection>
  #include <QDBusInterface>
  #include <QDBusReply>
  #include <QDBusAbstractAdaptor>
  """.}

  type MprisRoot = object

  dbusInterface MprisRoot, "org.mpris.MediaPlayer2":
    proc Raise = discard
    proc Quit = quit(0)

    property bool CanRaise:
      get: false
    
    property bool CanQuit:
      get: true
    
    property bool HasTrackList:
      get: false
    
    property bool CanSetFullscreen:
      get: false
    
    property bool Fullscreen:
      get: false
      set: discard value
    
    property string Identity:
      get: "DMusic"
    
    property string DesktopEntry:
      get: "dmusic"
    
    # property seq[string] SupportedUriSchemes:
    #   get: @[]
    
    # property seq[string] SupportedMimeTypes:
    #   get: @[]

  # registerSingletonInQml MprisRoot, "DMusic", 1, 1


  type
    QDBusObjectPath {.importcpp, header: "QDBusObjectPath".} = object

  type MprisPlayer = object

  dbusInterface MprisPlayer, "org.mpris.MediaPlayer2":
    proc PlayPause =
      if player.state == psPlaying: pause()
      else: play()
    
    proc Play = play()
    proc Pause = pause()
    proc Stop = stop()
    proc Next = next()
    proc Previous = prev()
    proc Seek(pos: int) = player.position = player.position + pos div 1000
    proc SetPosition(_: QDBusObjectPath, pos: int) = player.position = pos div 1000

    property bool CanControl:
      get: true
    
    property bool CanSeek:
      get: player.state != psStopped
    
    property bool CanPause:
      get: player.state == psPlaying
    
    property bool CanStop:
      get: player.state != psStopped
    
    property bool CanPlay:
      get: player.state == psPaused
    
    property bool CanGoPrevious:
      get: player.state != psStopped
    
    property bool CanGoNext:
      get: player.state != psStopped
    
    property int Position:
      get: player.position * 1000
      notify Seeked
    
    property float MinimumRate:
      get: 1.0
    
    property float MaximumRate:
      get: 1.0
    
    property float Rate:
      get: 1.0
      set: discard value
    
    property int volume:
      get: player.volume
      set: config.volume = sqrt(value / 100)
    
    property bool Shuffle:
      get: config.shuffle
      set: config.shuffle = value
    
    property string LoopStatus:
      get:
        case config.loop
        of LoopMode.none: "None"
        of LoopMode.track: "Track"
        of LoopMode.playlist: "Playlist"
      set:
        config.loop = case value
        of "None": LoopMode.none
        of "Track": LoopMode.track
        of "Playlist": LoopMode.playlist
        else: LoopMode.none
      
    property string PlaybackStatus:
      get:
        case player.state
        of psPlaying: "Playing"
        of psPaused: "Paused"
        of psStopped: "Stopped"
  
    proc `=new` =
      notifyPositionChanged &= proc() =
        this.Seeked
      
      {.emit: """
      auto&& bus = QDBusConnection::sessionBus();
      int _serviceDuplicateCount = 1;
      while (!bus.registerService(QString("org.mpris.MediaPlayer2.DMusic") + (_serviceDuplicateCount == 1? "" : QString::number(_serviceDuplicateCount)))) {
        ++_serviceDuplicateCount;
      }
      bus.registerObject("/org/mpris/MediaPlayer2", `this`);
      """.}

  # registerSingletonInQml MprisPlayer, "DMusic", 1, 1
  # todo: fix crush

let discord = newDiscordRPC(830725995769626624)
try:
  if config.discord_presence:
    discard discord.connect
except: discard

notify_discord_presence_changed &= proc =
  try:
    if config.discord_presence:
      discard discord.connect
  except: discard

proc update_discord_presence =
  discord.setActivity Activity(
    details:
      if current_track.comment == "": current_track.title
      else: &"{current_track.title} ({current_track.comment})",
    state: current_track.artists,
    assets: some ActivityAssets(
      large_image: "app",
      large_text:
        if current_track.kind == TrackKind.yandex: $current_track.yandex.id
        else: ""
    ),
    timestamps: ActivityTimestamps(
      start: epochTime().int64
    )
  )

notify_track_changed &= proc =
  if config.discord_presence:
    try: update_discord_presence()
    except: discard
