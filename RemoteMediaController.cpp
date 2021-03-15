#include "RemoteMediaController.hpp"
#include <QGuiApplication>

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
  //    connect(&player, &IPlayer::canSeekChanged, this, &Mpris2Player::onCanSeekChanged);
  //    connect(&player, &IPlayer::canGoNextChanged, this, &Mpris2Player::onCanGoNextChanged);
  //    connect(&player, &IPlayer::canGoPreviousChanged, this, &Mpris2Player::onCanGoPreviousChanged);
//  connect(&player, &MediaPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);

  //    connect(&localAlbumArt, &ILocalAlbumArt::urlChanged, this, &Mpris2Player::onArtUrlChanged);
}

QString Mpris2Player::playbackStatus()
{
  switch (_player->state()) {
  case QMediaPlayer::PlayingState: return "Playing";
  case QMediaPlayer::PausedState: return "Paused";
  default: return "Stopped";
  }
}

QString Mpris2Player::loopStatus()
{
  return "None";
}

void Mpris2Player::setLoopStatus(const QString&)
{
}

bool Mpris2Player::shuffle()
{
  return false;
}

void Mpris2Player::setShuffle(bool)
{
}

double Mpris2Player::volume()
{
  return 0.2;
}

void Mpris2Player::setVolume(double value)
{
  Q_UNUSED(value)
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
  return true;
  return _player->paused();
}

bool Mpris2Player::canStop()
{
  return true;
  return _player->playing() | _player->paused();
}

bool Mpris2Player::canPause()
{
  return true;
  return _player->playing();
}

bool Mpris2Player::canSeek()
{
  return true;
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

void Mpris2Player::onFavoriteChanged()
{
}

void Mpris2Player::onProgressChanged(qint64 ms)
{
  emit Seeked(ms * 1000);
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

void Mpris2Player::onCanSeekChanged()
{
}

void Mpris2Player::onCanGoPreviousChanged()
{
}

void Mpris2Player::onCanGoNextChanged()
{
}

void Mpris2Player::onVolumeChanged()
{
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
  QString trackId = QString("/org/mpris/MediaPlayer2/MellowPlayer/Track/") + QString::number(0); //TODO
  res["mpris:trackid"] = QVariant(QDBusObjectPath(trackId).path());
  res["mpris:artUrl"] = track.cover(); //TODO: coverFile();
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
  for (auto it = map.begin(); it != map.end(); ++it)
  {
    // Format output here.
    output += QString("\n\t%1=%2,").arg(it.key()).arg(it.value().toString());
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
  if (!bus.registerService(serviceName) || !bus.registerObject("/org/mpris/MediaPlayer2", this))
    throw std::runtime_error(qPrintable(QDBusConnection::sessionBus().lastError().message()));

  _mpris2Root = new Mpris2Root(this);

  _isDBusServiceCreated = true;
}

void RemoteMediaController::setTarget(MediaPlayer* player)
{
  if (!_isDBusServiceCreated) return;
  _mpris2Player = new Mpris2Player(player, this);
}
