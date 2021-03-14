#include "remotecontroller.hpp"
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


Mpris2Player::Mpris2Player(QObject* parent)
  : QDBusAbstractAdaptor(parent)
{
  //    connect(&player, &IPlayer::playbackStatusChanged, this, &Mpris2Player::onPlaybackStatusChanged);
  //    connect(&player, &IPlayer::currentSongChanged, this, &Mpris2Player::onSongChanged);
  //    connect(&player, &IPlayer::positionChanged, this, &Mpris2Player::onPositionChanged);
  //    connect(&player, &IPlayer::canSeekChanged, this, &Mpris2Player::onCanSeekChanged);
  //    connect(&player, &IPlayer::canGoNextChanged, this, &Mpris2Player::onCanGoNextChanged);
  //    connect(&player, &IPlayer::canGoPreviousChanged, this, &Mpris2Player::onCanGoPreviousChanged);
  //    connect(&player, &IPlayer::volumeChanged, this, &Mpris2Player::onVolumeChanged);

  //    connect(&localAlbumArt, &ILocalAlbumArt::urlChanged, this, &Mpris2Player::onArtUrlChanged);
}

QString Mpris2Player::playbackStatus()
{
  return "Stopped";
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
  Track a;
  return RemoteController::toXesam(a);
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

qint64 Mpris2Player::position()
{
  return 0 * 1000;
}

bool Mpris2Player::canGoNext()
{
  return true;
}

bool Mpris2Player::canGoPrevious()
{
  return true;
}

bool Mpris2Player::canPlay()
{
  return true;
}

bool Mpris2Player::canStop()
{
  return true;
}

bool Mpris2Player::canPause()
{
  return true;
}

bool Mpris2Player::canSeek()
{
  return true;
}

bool Mpris2Player::canControl()
{
  return true;
}

void Mpris2Player::PlayPause()
{
}

void Mpris2Player::Play()
{
}

void Mpris2Player::Pause()
{
}

void Mpris2Player::Stop()
{
}

void Mpris2Player::Next()
{
}

void Mpris2Player::Previous()
{
}

void Mpris2Player::Seek(qint64 position)
{
  Q_UNUSED(position)
}

void Mpris2Player::SetPosition(const QDBusObjectPath&, qint64 position)
{
  Q_UNUSED(position)
}

void Mpris2Player::onPlaybackStatusChanged()
{
}

void Mpris2Player::onSongChanged(Track* track)
{
  Q_UNUSED(track)
}

void Mpris2Player::onFavoriteChanged()
{
}

void Mpris2Player::onArtUrlChanged()
{
}

void Mpris2Player::onPositionChanged()
{
}

void Mpris2Player::onDurationChanged()
{
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

void Mpris2Player::signalPlayerUpdate(const QVariantMap& map)
{
  auto mapWithMetadata = map;
  Track a;
  mapWithMetadata["Metadata"] = RemoteController::toXesam(a);
  signalUpdate(mapWithMetadata, "org.mpris.MediaPlayer2.Player");
}

void Mpris2Player::signalUpdate(const QVariantMap& map, const QString& interfaceName)
{
  if (!map.isEmpty())
  {
    QDBusMessage signal = QDBusMessage::createSignal("/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties", "PropertiesChanged");
    QVariantList args = QVariantList() << interfaceName << map << QStringList();
    signal.setArguments(args);

    QDBusConnection::sessionBus().send(signal);
  }
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



RemoteController::~RemoteController()
{
  auto&& bus = QDBusConnection::sessionBus();
  bus.unregisterObject("/org/mpris/MediaPlayer2");
  bus.unregisterService(serviceName);
}

RemoteController::RemoteController(QObject *parent) : QObject(parent)
{
  auto&& bus = QDBusConnection::sessionBus();

  if (!bus.isConnected())
    throw std::runtime_error("Cannot connect to the D-Bus session bus.");
  if (_isDBusServiceCreated) return;
  if (!bus.registerService(serviceName) || !bus.registerObject("/org/mpris/MediaPlayer2", this))
    throw std::runtime_error(qPrintable(QDBusConnection::sessionBus().lastError().message()));

  _mpris2Root = new Mpris2Root(this);
  _mpris2Player = new Mpris2Player(this);

  _isDBusServiceCreated = true;
  //  bus.connect(serviceName, mpris, "Player", "Seeked", this, SIGNAL(seek));
}

QMap<QString, QVariant> RemoteController::toXesam(Track& track)
{
  QMap<QString, QVariant> res;
  res["origin"] = "DMusic";
  QStringList artist;
  artist.append(track.author());
  res["xesam:url"] = track.title();
  res["xesam:artist"] = artist;
  res["xesam:album"] = ""; //TODO
  res["xesam:title"] = track.title();
  res["xesam:userRating"] = 0; //TODO
  auto duration = track.duration();
  if (duration > 0)
    res["mpris:length"] = duration * 1000; // in microseconds
  else
    res["mpris:length"] = 1;
  QString trackId = QString("/org/mpris/MediaPlayer2/MellowPlayer/Track/") + QString::number(0); //TODO
  res["mpris:trackid"] = QVariant(QDBusObjectPath(trackId).path());
  res["mpris:artUrl"] = track.cover(); //TODO: coverFile();
  return res;
}
