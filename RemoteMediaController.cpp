#include "RemoteMediaController.hpp"
#include <QGuiApplication>
#include <stdexcept>
#include "utils.hpp"

using namespace py;

Mpris2Root::Mpris2Root(QObject* parent) : QDBusAbstractAdaptor(parent)
{
}

void Mpris2Root::Raise()
{
  //TODO
}

void Mpris2Root::Quit()
{
  QGuiApplication::instance()->quit();
}

bool Mpris2Root::canRaise()
{
  return true;
}

bool Mpris2Root::canQuit()
{
  return true;
}

bool Mpris2Root::hasTrackList()
{
  return false;
}

bool Mpris2Root::canSetFullscreen()
{
  return false;
}

bool Mpris2Root::fullscreen()
{
  return false;
}

void Mpris2Root::setFullscreen(bool value)
{
  Q_UNUSED(value);
}

QString Mpris2Root::identity()
{
  return "DMusic";
}

QString Mpris2Root::desktopEntry()
{
  return "dmusic";
}

QStringList Mpris2Root::supportedUriSchemes()
{
  return QStringList();
}

QStringList Mpris2Root::supportedMimeTypes()
{
  return QStringList();
}


Mpris2Player::Mpris2Player(AudioPlayer* player, QObject* parent) : QDBusAbstractAdaptor(parent), _player(player)
{
  _currentTrackMetadata = toXesam(*AudioPlayer::noneTrack);

  connect(_player, &AudioPlayer::currentTrackChanged, this, &Mpris2Player::onTrackChanged);
  connect(_player, &AudioPlayer::stateChanged, this, &Mpris2Player::onStateChanged);
  connect(_player, &AudioPlayer::progressChanged, this, &Mpris2Player::onProgressChanged);
  connect(_player, &AudioPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
  connect(_player, &AudioPlayer::nextModeChanged, this, &Mpris2Player::onNextModeChanged);
  connect(_player, &AudioPlayer::loopModeChanged, this, &Mpris2Player::onLoopModeChanged);
}

QString Mpris2Player::playbackStatus()
{
  switch (_player->state()) {
  case QMediaPlayer::PlayingState: return "Playing";
  case QMediaPlayer::PausedState: return "Paused";
  default: return "Stopped";
  }
}

bool Mpris2Player::shuffle()
{
  return _player->nextMode() != Settings::NextSequence;
}

void Mpris2Player::setShuffle(bool value)
{
  _player->setNextMode(value? Settings::NextShuffle : Settings::NextSequence);
}

QString Mpris2Player::loopStatus()
{
  switch (_player->loopMode()) {
  case Settings::LoopPlaylist: return "Playlist";
  case Settings::LoopTrack: return "Track";
  default: return "None";
  }
}

void Mpris2Player::setLoopStatus(const QString& value)
{
  if (value == "Playlist") _player->setLoopMode(Settings::LoopPlaylist);
  else if (value == "Track") _player->setLoopMode(Settings::LoopTrack);
  else _player->setLoopMode(Settings::LoopNone);
}

double Mpris2Player::volume()
{
  return _player->volume();
}

void Mpris2Player::setVolume(double value)
{
  disconnect(_player, &AudioPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
  _player->setVolume(value);
  connect(_player, &AudioPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
}

QVariantMap Mpris2Player::metadata()
{
  return _currentTrackMetadata;
}

double Mpris2Player::minimumRate()
{
  return 1.0;
}

double Mpris2Player::maximumRate()
{
  return 1.0;
}

double Mpris2Player::rate()
{
  return 1.0;
}

void Mpris2Player::setRate(float)
{
}

qlonglong Mpris2Player::position()
{
  return _player->progress_ms() * 1000;
}

bool Mpris2Player::canGoNext()
{
  return _player->state() != QMediaPlayer::StoppedState;
}

bool Mpris2Player::canGoPrevious()
{
  return _player->state() != QMediaPlayer::StoppedState;
}

bool Mpris2Player::canPlay()
{
  return _player->state() == QMediaPlayer::PausedState;
}

bool Mpris2Player::canStop()
{
  return _player->state() != QMediaPlayer::StoppedState;
}

bool Mpris2Player::canPause()
{
  return _player->state() == QMediaPlayer::PlayingState;
}

bool Mpris2Player::canSeek()
{
  return _player->state() != QMediaPlayer::StoppedState;
}

bool Mpris2Player::canControl()
{
  return true;
}

void Mpris2Player::PlayPause()
{
  _player->pause_or_play();
}

void Mpris2Player::Play()
{
  _player->play();
}

void Mpris2Player::Pause()
{
  _player->pause();
}

void Mpris2Player::Stop()
{
  _player->stop();
}

void Mpris2Player::Next()
{
  _player->next();
}

void Mpris2Player::Previous()
{
  _player->prev();
}

void Mpris2Player::Seek(qint64 position)
{
  _player->setProgress_ms(_player->progress_ms() + position / 1000);
}

void Mpris2Player::SetPosition(const QDBusObjectPath&, qint64 position)
{
  _player->setProgress_ms(position / 1000);
}

void Mpris2Player::onStateChanged(QMediaPlayer::State state)
{
  QVariantMap map;
  map["PlaybackStatus"] = stateToString(state);

  switch (_player->state()) {
  case QMediaPlayer::PlayingState:
    map["CanPlay"] = false;
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

  signalPlayerUpdate(map);
}

void Mpris2Player::onTrackChanged(Track* track)
{
  _currentTrackMetadata = toXesam(*track);
  signalPlayerUpdate({});
  connect(track, &Track::titleChanged, this, &Mpris2Player::onTitleChanged);
  connect(track, &Track::artistsStrChanged, this, &Mpris2Player::onAuthorChanged);
  connect(track, &Track::coverChanged, this, &Mpris2Player::onCoverChanged);
  connect(track, &Track::durationChanged, this, &Mpris2Player::onDurationChanged);
}

void Mpris2Player::onProgressChanged(qint64 ms)
{
  if (std::abs(ms - _prevPosition) > 100 || ms == 0 || _prevPosition == 0) //TODO: seek minimum by Settings
    emit Seeked(ms * 1000);
  _prevPosition = ms;
}

void Mpris2Player::onTitleChanged(QString title)
{
  _currentTrackMetadata["xesam:url"] = title;
  _currentTrackMetadata["xesam:title"] = title;
  signalPlayerUpdate({});
}

void Mpris2Player::onAuthorChanged(QString author)
{
  QStringList artist;
  artist.append(author);
  _currentTrackMetadata["xesam:artist"] = artist;
  signalPlayerUpdate({});
}

void Mpris2Player::onCoverChanged(QString cover)
{
  _currentTrackMetadata["mpris:artUrl"] = cover;
  signalPlayerUpdate({});
}

void Mpris2Player::onDurationChanged(qint64 duration)
{
  _currentTrackMetadata["mpris:length"] = duration > 0? duration * 1000 : 1;
  signalPlayerUpdate({});
}

void Mpris2Player::onVolumeChanged(double volume)
{
  QVariantMap map;
  map["Volume"] = volume;
  signalUpdate(map, "org.mpris.MediaPlayer2.Player");
}

void Mpris2Player::onLoopModeChanged(Settings::LoopMode)
{
  QVariantMap map;
  map["LoopStatus"] = loopStatus();
  signalUpdate(map, "org.mpris.MediaPlayer2.Player");
}

void Mpris2Player::onNextModeChanged(Settings::NextMode)
{
  QVariantMap map;
  map["Shuffle"] = shuffle();
  signalUpdate(map, "org.mpris.MediaPlayer2.Player");
}

QMap<QString, QVariant> Mpris2Player::toXesam(Track& track)
{
  QMap<QString, QVariant> res;
  res["origin"] = "DMusic";
  QStringList artist{track.artistsStr()};
  auto title = track.title();
  res["xesam:url"] = title;
  res["xesam:artist"] = artist;
  res["xesam:album"] = ""; //TODO
  res["xesam:title"] = title;
  res["xesam:userRating"] = track.liked()? 1 : 0;
  auto duration = track.duration();
  res["mpris:length"] = duration > 0? duration * 1000 : 1; // in microseconds
  QString trackId = QString("/org/mpris/MediaPlayer2/DMusic/Track/") + track.idInt();
  res["mpris:trackid"] = QVariant(QDBusObjectPath(trackId).path());
  res["mpris:artUrl"] = track.cover();
  return res;
}

void Mpris2Player::signalPlayerUpdate(const QVariantMap& map)
{
  auto mapWithMetadata = map;
  mapWithMetadata["Metadata"] = _currentTrackMetadata;
  signalUpdate(mapWithMetadata, "org.mpris.MediaPlayer2.Player");
}

void Mpris2Player::signalUpdate(const QVariantMap& map, const QString& interfaceName)
{
  if (map.isEmpty()) return;

  QDBusMessage signal = QDBusMessage::createSignal("/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged");
  QVariantList args = QVariantList() << interfaceName << map << QStringList();
  signal.setArguments(args);

  QDBusConnection::sessionBus().send(signal);
}

QString Mpris2Player::qMapToString(const QMap<QString, QVariant>& map)
{
  QString output;
  for (auto it = map.begin(); it != map.end(); ++it) {
    output += QString("\n\t%1=%2,").arg(it.key(), it.value().toString());
  }
  return output;
}

QString Mpris2Player::stateToString(QMediaPlayer::State state)
{
  switch (state) {
  case QMediaPlayer::PlayingState: return "Playing";
  case QMediaPlayer::PausedState: return "Paused";
  default: return "Stopped";
  }
}

#ifdef Q_OS_WIN

ThumbnailController::ThumbnailController(MediaPlayer* player, QObject* parent) : QObject(parent), _player(player)
{
  _toolbar = new QWinThumbnailToolBar(this);
  auto windows = QGuiApplication::allWindows();
  _toolbar->setWindow(windows[0]);

  _pausePlay = new QWinThumbnailToolButton(_toolbar);
  _pausePlay->setEnabled(false);
  _pausePlay->setToolTip(tr("Play"));
  _pausePlay->setIcon(QIcon(":resources/player/play.svg"));
  connect(_pausePlay, &QWinThumbnailToolButton::clicked, _player, &MediaPlayer::pause_or_play);

  _next = new QWinThumbnailToolButton(_toolbar);
  _next->setEnabled(false);
  _next->setToolTip(tr("Next"));
  _next->setIcon(QIcon(":resources/player/next.svg"));
  connect(_next, &QWinThumbnailToolButton::clicked, _player, &MediaPlayer::next);

  _prev = new QWinThumbnailToolButton(_toolbar);
  _prev->setEnabled(false);
  _prev->setToolTip(tr("Previous"));
  _prev->setIcon(QIcon(":resources/player/prev.svg"));
  connect(_prev, &QWinThumbnailToolButton::clicked, _player, &MediaPlayer::prev);

  _toolbar->addButton(_prev);
  _toolbar->addButton(_pausePlay);
  _toolbar->addButton(_next);

  connect(_player, &MediaPlayer::stateChanged, this, &ThumbnailController::updateToolbar);
}

ThumbnailController::~ThumbnailController()
{

}

void ThumbnailController::updateToolbar()
{
  if (_player->state() == QMediaPlayer::PlayingState) {
    _pausePlay->setToolTip(tr("Pause"));
    _pausePlay->setIcon(QIcon(":resources/player/pause.svg"));
  } else {
    _pausePlay->setToolTip(tr("Play"));
    _pausePlay->setIcon(QIcon(":resources/player/play.svg"));
  }

  bool enabled = _player->state() != QMediaPlayer::StoppedState;
  _pausePlay->setEnabled(enabled);
  _next->setEnabled(enabled);
  _prev->setEnabled(enabled);
}

#endif

DiscordPresence::DiscordPresence(AudioPlayer* player, QObject* parent) : QObject(parent), _player(player)
{
  try {
    auto presence = py::module("pypresence", true);
    _time = module("time");
    _rpc = presence.call("Presence", "830725995769626624");

    //TODO: buttons

    _rpc.call("connect");

    connect(_player, &AudioPlayer::currentTrackChanged, this, &DiscordPresence::onTrackChanged);
  } catch(py_error const& e) {
    std::cerr << "failed to init discord presence: " << e.what();
  }
}

void DiscordPresence::update(Track* track)
{
  if (_rpc == py::none) return;
  auto author = track->artistsStr();
  auto details = track->title();
  if (author == "" || details == "") return;

  QtConcurrent::run([track, author, details, this]() {
    try {
      _rpc.call("clear");

      std::map<std::string, object> args;
      args["state"] = track->artistsStr();
      if (track->extra() == "")
        args["details"] = track->title();
      else
        args["details"] = track->title() + " (" + track->extra() + ")";
      args["start"] = _time.call("time");
      args["large_image"] = "app";
      args["large_text"] = track->idInt();
      _rpc.call("update", std::initializer_list<object>{}, args);
    }  catch (py_error const& e) {
      // it's normal ;)
    }
  });
}

void DiscordPresence::onTrackChanged(Track* track)
{
  disconnect(nullptr, nullptr, this, SLOT(updateData()));
  connect(track, &Track::artistsStrChanged, this, &DiscordPresence::updateData);
  connect(track, &Track::titleChanged, this, &DiscordPresence::updateData);
  connect(track, &Track::idIntChanged, this, &DiscordPresence::updateData);
  update(track);
}

void DiscordPresence::updateData()
{
  update(_player->currentTrack());
}


RemoteMediaController::~RemoteMediaController()
{
  if (!_isDBusServiceCreated) return;
  auto&& bus = QDBusConnection::sessionBus();
  bus.unregisterObject("/org/mpris/MediaPlayer2");
  bus.unregisterService(serviceName);
}

RemoteMediaController::RemoteMediaController(QObject *parent) : QObject(parent)
{
  auto&& bus = QDBusConnection::sessionBus();

  if (!bus.isConnected()) return;
  while (!bus.registerService(serviceName + (_serviceDuplicateCount == 1? "" : QString::number(_serviceDuplicateCount)))) {
    if (_serviceDuplicateCount > 20)
      throw std::runtime_error(qPrintable(QDBusConnection::sessionBus().lastError().message()));
    ++_serviceDuplicateCount;
  }

  if (!bus.registerObject("/org/mpris/MediaPlayer2", this))
    throw std::runtime_error(qPrintable(QDBusConnection::sessionBus().lastError().message()));

  _mpris2Root = new Mpris2Root(this);

  _isDBusServiceCreated = true;
}

AudioPlayer* RemoteMediaController::target()
{
  return _target;
}

void RemoteMediaController::setTarget(AudioPlayer* player)
{
  _target = player;
#ifdef Q_OS_WIN
  delete _win;
  _win = new ThumbnailController(player, this);
#endif
  _discordPresence = new DiscordPresence(player, this);
  if (!_isDBusServiceCreated) return;
  _mpris2Player = new Mpris2Player(player, this);
}
