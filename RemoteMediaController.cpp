#include "RemoteMediaController.hpp"
#include <QGuiApplication>
#include <stdexcept>

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
  //TODO
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


Mpris2Player::Mpris2Player(MediaPlayer* player, QObject* parent) : QDBusAbstractAdaptor(parent), _player(player)
{
  _currentTrackMetadata = toXesam(MediaPlayer::noneTrack);

  connect(_player, &MediaPlayer::currentTrackChanged, this, &Mpris2Player::onTrackChanged);
  connect(_player, &MediaPlayer::stateChanged, this, &Mpris2Player::onStateChanged);
  connect(_player, &MediaPlayer::progressChanged, this, &Mpris2Player::onProgressChanged);
  connect(_player, &MediaPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
}

QString Mpris2Player::playbackStatus()
{
  switch (_player->state()) {
  case QMediaPlayer::PlayingState: return "Playing";
  case QMediaPlayer::PausedState: return "Paused";
  default: return "Stopped";
  }
}

//bool Mpris2Player::shuffle()
//{
//  return false;
//}

//void Mpris2Player::setShuffle(bool)
//{
//}

//QString Mpris2Player::loopStatus()
//{
//  return "None";
//}

//void Mpris2Player::setLoopStatus(const QString&)
//{
//}

double Mpris2Player::volume()
{
  return _player->volume();
}

void Mpris2Player::setVolume(double value)
{
  disconnect(_player, &MediaPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
  _player->setVolume(value);
  connect(_player, &MediaPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);
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
  return false;
}

bool Mpris2Player::canGoPrevious()
{
  return false;
}

bool Mpris2Player::canPlay()
{
  return _player->paused();
}

bool Mpris2Player::canStop()
{
  return _player->playing() | _player->paused();
}

bool Mpris2Player::canPause()
{
  return _player->playing();
}

bool Mpris2Player::canSeek()
{
  return _player->playing() | _player->paused();
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
  _player->unpause();
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
}

void Mpris2Player::Previous()
{
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
    break;
  case QMediaPlayer::PausedState:
    map["CanPlay"] = true;
    map["CanStop"] = true;
    map["CanPause"] = false;
    map["CanSeek"] = true;
    break;
  default:
    map["CanPlay"] = false;
    map["CanStop"] = false;
    map["CanPause"] = false;
    map["CanSeek"] = false;
    break;
  }

  signalPlayerUpdate(map);
}

void Mpris2Player::onTrackChanged(Track* track)
{
  _currentTrackMetadata = toXesam(*track);
  signalPlayerUpdate({});
  connect(track, &Track::titleChanged, this, &Mpris2Player::onTitleChanged);
  connect(track, &Track::authorChanged, this, &Mpris2Player::onAuthorChanged);
  connect(track, &Track::coverChanged, this, &Mpris2Player::onCoverChanged);
  connect(track, &Track::durationChanged, this, &Mpris2Player::onDurationChanged);
}

void Mpris2Player::onProgressChanged(qint64 ms)
{
  if (labs(ms - _prevPosition) > 100 || ms == 0 || _prevPosition == 0) //TODO: seek minimum by Settings
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

QMap<QString, QVariant> Mpris2Player::toXesam(Track& track)
{
  QMap<QString, QVariant> res;
  res["origin"] = "DMusic";
  QStringList artist;
  artist.append(track.author());
  auto title = track.title();
  res["xesam:url"] = title;
  res["xesam:artist"] = artist;
  res["xesam:album"] = ""; //TODO
  res["xesam:title"] = title;
  res["xesam:userRating"] = 0; //TODO
  auto duration = track.duration();
  res["mpris:length"] = duration > 0? duration * 1000 : 1; // in microseconds
  QString trackId = QString("/org/mpris/MediaPlayer2/DMusic/Track/") + QString::number(0); //TODO
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

MediaPlayer* RemoteMediaController::target()
{
  return _target;
}

void RemoteMediaController::setTarget(MediaPlayer* player)
{
  if (!_isDBusServiceCreated) return;
  _mpris2Player = new Mpris2Player(player, this);
  _target = player;
}
