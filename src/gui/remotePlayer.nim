{.used.}

when defined(linux):
  import math
  import qt
  import ../[api]
  import audio, configuration
  
  {.emit: """
  #include <QDBusConnection>
  #include <QDBusInterface>
  #include <QDBusReply>
  """.}

  {.emit: """/*TYPESECTION*/
  using QString2QVariantMap = QMap<QString, QVariant>;
  """.}

  type
    QDBusAbstractAdaptor {.importcpp, header: "QDBusAbstractAdaptor".} = object of QObject
    QDBusObjectPath {.importcpp, header: "QDBusObjectPath".} = object

    QString2QVariantMap {.importcpp: "QString2QVariantMap", header: "QMap", header: "QString", header: "QVariant".} = object
    QVariantMap {.importcpp: "QVariantMap", header: "QVariantMap".} = object
  

  proc emptyVariantMap(): QVariantMap {.importcpp: "{@}", header: "QVariantMap".}


  proc toXesam(track: Track): ptr QString2QVariantMap =
    let artistsStr = track.artists.toQString
    let idStr = ($track.id).toQString
    let cover = track.coverOrUrl.toQString
    let trackTitle = track.title.toQString
    let trackDuration = track.duration
    {.emit: """
    `result` = new QString2QVariantMap();
    (*`result`)["origin"] = "DMusic";
    QStringList artist;
    for (auto& x : `artistsStr`.split(", "))
      artist.append(x);
    auto title = `trackTitle`;
    (*`result`)["xesam:url"] = title;
    (*`result`)["xesam:artist"] = artist;
    (*`result`)["xesam:album"] = ""; //TODO
    (*`result`)["xesam:title"] = title;
    (*`result`)["xesam:userRating"] = 0; //TODO
    qlonglong duration = `trackDuration`;
    (*`result`)["mpris:length"] = duration > 0? duration * 1000 : 1; // in microseconds
    auto id = `idStr`;
    QString trackId = QString("/org/mpris/MediaPlayer2/DMusic/track/") + (id == ""? QString::number(0) : id);
    (*`result`)["mpris:trackid"] = QVariant(QDBusObjectPath(trackId).path());
    (*`result`)["mpris:artUrl"] = `cover`;
    """.}
  
  proc signalUpdate(map: QVariantMap, iface: QString) =
    {.emit: """
    if (`map`.isEmpty()) return;

    QDBusMessage signal = QDBusMessage::createSignal("/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged");
    QVariantList args = QVariantList() << `iface` << `map` << QStringList();
    signal.setArguments(args);

    QDBusConnection::sessionBus().send(signal);
    """.}

  proc signalPlayerUpdate(metadata: ptr QString2QVariantMap, map: QVariantMap) =
    var vmap = map
    {.emit: """
    `vmap`["Metadata"] = *`metadata`;
    """.}
    signalUpdate(vmap, "org.mpris.MediaPlayer2.Player".toQString)
  
  proc onStateChanged(metadata: ptr QString2QVariantMap, state: PlayerState) =
    var map: QVariantMap
    let stateString = toQString:
      case state
      of psPlaying: "Playing"
      of psPaused: "Paused"
      of psStopped: "Stopped"
    {.emit: """
    map["PlaybackStatus"] = `stateString`;

    switch (`state`) {
    case QMediaPlayer::PlayingState:
      map["CanPlay"] = true;
      map["CanStop"] = true;
      map["CanPause"] = true;
      map["CanSeek"] = true;
      map["CanGoNext"] = true;
      map["CanGoPrevious"] = true;
      break;
    case QMediaPlayer::PausedState:
      map["CanPlay"] = true;
      map["CanStop"] = true;
      map["CanPause"] = false;
      map["CanSeek"] = true;
      map["CanGoNext"] = true;
      map["CanGoPrevious"] = true;
      break;
    default:
      map["CanPlay"] = false;
      map["CanStop"] = false;
      map["CanPause"] = false;
      map["CanSeek"] = false;
      map["CanGoNext"] = false;
      map["CanGoPrevious"] = false;
      break;
    }
    """.}
    signalPlayerUpdate(metadata, map)

  
  type MprisRoot = object

  qobject MprisRoot of QDBusAbstractAdaptor:
    classinfo "D-Bus Interface", "org.mpris.MediaPlayer2"

    proc Raise =
      ## todo
    
    proc Quit =
      # raise Defect.newException("quit")
      quit(0)

    property bool CanRaise:
      get: true
    
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
    
    property QStringList SupportedUriSchemes:
      get: @[].toQStringList
    
    property QStringList SupportedMimeTypes:
      # get: @["audio/mpeg"].toQStringList
      get: @[].toQStringList

    proc `=new` = discard


  type MprisPlayer = object
    trackMetadata: ptr QString2QVariantMap

  qobject MprisPlayer of QDBusAbstractAdaptor:
    classinfo "D-Bus Interface", "org.mpris.MediaPlayer2.Player"

    proc PlayPause =
      if player.state == psPlaying: pause()
      else: play()
    
    proc Play = play()
    proc Pause = pause()
    proc Stop = stop()
    proc Next = next()
    proc Previous = prev()
    proc Seek(pos: int) = player.position = player.position + pos div 1000
    proc SetPosition(p: QDBusObjectPath, pos: int) = player.position = pos div 1000

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
        ## todo
      
      notify_track_changed &= proc() =
        self.trackMetadata = currentTrack.toXesam
        signalPlayerUpdate(self.trackMetadata, emptyVariantMap())

      notify_player_state_changed &= proc() =
        onStateChanged(self.trackMetadata, player.state)
  

  type RemotePlayer = object

  qobject RemotePlayer:
    proc `=new` =
      {.emit: """
      auto&& bus = QDBusConnection::sessionBus();
      int _serviceDuplicateCount = 1;
      while (!bus.registerService(QString("org.mpris.MediaPlayer2.DMusic") + (_serviceDuplicateCount == 1? "" : QString::number(_serviceDuplicateCount)))) {
        ++_serviceDuplicateCount;
      }
      bus.registerObject("/org/mpris/MediaPlayer2", `this`);
      """.}

  
  type CppRemotePlayer {.importcpp: "RemotePlayer".} = object of QDBusAbstractAdaptor
  proc newRemotePlayer(): ptr CppRemotePlayer {.importcpp: "new RemotePlayer()".}
  let remote_player {.used.} = newRemotePlayer()

  type CppMprisRoot {.importcpp: "MprisRoot".} = object
  proc newMprisRoot(parent: ptr CppRemotePlayer): ptr CppMprisRoot {.importcpp: "new MprisRoot(@)".}
  let mpris_root {.used.} = newMprisRoot(remote_player)

  type CppMprisPlayer {.importcpp: "MprisPlayer".} = object of QDBusAbstractAdaptor
  proc newMprisPlayer(parent: ptr CppRemotePlayer): ptr CppMprisPlayer {.importcpp: "new MprisPlayer(@)".}
  let mpris_player {.used.} = newMprisPlayer(remote_player)

