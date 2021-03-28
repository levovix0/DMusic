#include "mediaplayer.hpp"
#include "settings.hpp"
#include "QDateTime"
#include "Log.hpp"

MediaPlayer::~MediaPlayer()
{
  delete player;
}

MediaPlayer::MediaPlayer(QObject *parent) : QObject(parent), player(new QMediaPlayer(this)), _currentTrack(nullptr)
{
  player->setNotifyInterval(50);
  player->setVolume(50);
  _volume = 0.5;
  _currentTrack = &noneTrack;

  QObject::connect(player, &QMediaPlayer::stateChanged, [this](QMediaPlayer::State state) {
    if (state == QMediaPlayer::PlayingState) {
    }
    else if (state == QMediaPlayer::StoppedState) {
      if (_loopMode == Settings::LoopTrack && player->mediaStatus() == QMediaPlayer::EndOfMedia) {
        player->play();
        return;
      }

      if (_currentPlaylist != nullptr && player->mediaStatus() == QMediaPlayer::EndOfMedia) {
        if (next()) return;
      }

      if (_currentTrack != &noneTrack && _currentTrack != nullptr) {
        QObject::disconnect(_currentTrack, &Track::mediaChanged, this, &MediaPlayer::setMedia);
        QObject::disconnect(_currentTrack, &Track::mediaAborted, this, &MediaPlayer::onMediaAborted);
      }

      _currentTrack = &noneTrack;
      emit currentTrackChanged(_currentTrack);

      player->setMedia(QMediaContent());
      player->setPosition(0);
    }
    else if (state == QMediaPlayer::PausedState) {
    }
    emit stateChanged(state);
  });
  QObject::connect(player, &QMediaPlayer::mediaChanged, [this](QMediaContent const& media) {
    if (media.isNull()) emit durationChanged(0);
  });

  QObject::connect(player, &QMediaPlayer::positionChanged, this, &MediaPlayer::progressChanged);
  QObject::connect(player, &QMediaPlayer::durationChanged, this, &MediaPlayer::durationChanged);
  QObject::connect(player, &QMediaPlayer::mutedChanged, this, &MediaPlayer::mutedChanged);
}

void MediaPlayer::play(Track* track)
{
  if (track == nullptr) return play(&noneTrack);
  _currentPlaylist = nullptr;
  updatePlaylistGenerator();

  if (state() != QMediaPlayer::StoppedState) {
    player->stop();
  }

  _currentTrack = track;

  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaChanged, this, &MediaPlayer::setMedia);
  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaAborted, this, &MediaPlayer::onMediaAborted);

  emit currentTrackChanged(_currentTrack);

  player->setMedia(track->media());
  player->setPosition(0);
  player->play();
}

void MediaPlayer::play(Playlist* playlist)
{
  if (playlist == nullptr) return play(&noneTrack);

  if (state() != QMediaPlayer::StoppedState) {
    player->stop();
  }

  _currentPlaylist = playlist;
  updatePlaylistGenerator();

  _currentTrack = _gen.first(); // next
  if (_currentTrack == nullptr) return play(&noneTrack);

  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaChanged, this, &MediaPlayer::setMedia);
  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaAborted, this, &MediaPlayer::onMediaAborted);

  emit currentTrackChanged(_currentTrack);

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
}

float MediaPlayer::progress()
{
  auto duration = this->duration();
  return duration != 0? ((float)progress_ms() / (float)duration) : 0;
}

qint64 MediaPlayer::progress_ms()
{
  return player->position();
}

Track* MediaPlayer::currentTrack()
{
  return _currentTrack;
}

QString MediaPlayer::formatProgress()
{
  return formatTime(progress_ms() / 1000);
}

QString MediaPlayer::formatDuration()
{
  return formatTime(duration() / 1000);
}

qint64 MediaPlayer::duration()
{
  return player->media().isNull()? 0 : player->duration();
}

QMediaPlayer::State MediaPlayer::state()
{
  return player->state();
}

double MediaPlayer::volume()
{
  return _volume;
}

bool MediaPlayer::muted()
{
  return player->isMuted();
}

Settings::LoopMode MediaPlayer::loopMode()
{
  return _loopMode;
}

Settings::NextMode MediaPlayer::nextMode()
{
  return _nextMode;
}

void MediaPlayer::setMedia(QMediaContent media)
{
  player->setMedia(media);
  player->setPosition(0);
  player->play();
}

void MediaPlayer::onMediaAborted()
{
  logging.error("media aborted");
  next();
}

void MediaPlayer::updatePlaylistGenerator()
{
  if (_currentPlaylist == nullptr) {
    _gen = {[]{return nullptr;}, []{return nullptr;}};
    return;
  }
  _gen = _currentPlaylist->generator(-1, nextMode());
}

void MediaPlayer::pause_or_play()
{
  if (state() == QMediaPlayer::PlayingState) {
    player->pause();
  } else {
    player->play();
  }
}

void MediaPlayer::pause()
{
  player->pause();
}

void MediaPlayer::play()
{
  player->play();
}

void MediaPlayer::stop()
{
  play(&noneTrack);
}

bool MediaPlayer::next()
{
  if (state() != QMediaPlayer::StoppedState) {
    player->stop();
  }

  _currentTrack = _gen.first(); // next
  if (_currentTrack == nullptr) return false;

  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaChanged, this, &MediaPlayer::setMedia);
  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaAborted, this, &MediaPlayer::onMediaAborted);

  emit currentTrackChanged(_currentTrack);

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
  return true;
}

bool MediaPlayer::prev()
{
  if (state() != QMediaPlayer::StoppedState) {
    player->stop();
  }

  _currentTrack = _gen.second(); // prev
  if (_currentTrack == nullptr) return false;

  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaChanged, this, &MediaPlayer::setMedia);
  if (_currentTrack != &noneTrack) QObject::connect(_currentTrack, &Track::mediaAborted, this, &MediaPlayer::onMediaAborted);

  emit currentTrackChanged(_currentTrack);

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
  return true;
}

void MediaPlayer::setCurrentTrack(Track* v)
{
  play(v);
}

void MediaPlayer::setProgress(float progress)
{
  player->setPosition(player->duration() * progress);
}

void MediaPlayer::setProgress_ms(int progress)
{
  player->setPosition(progress);
}

void MediaPlayer::setVolume(double volume)
{
  volume = qMin(1.0, qMax(0.0, volume));
  player->setVolume(qRound((volume * volume) * 100)); // volume^2
  _volume = volume;
  emit volumeChanged(volume);
}

void MediaPlayer::setMuted(bool muted)
{
  player->setMuted(muted);
}

void MediaPlayer::setLoopMode(Settings::LoopMode loopMode)
{
  _loopMode = loopMode;
  emit loopModeChanged(loopMode);
}

void MediaPlayer::setNextMode(Settings::NextMode nextMode)
{
  _nextMode = nextMode;
  updatePlaylistGenerator();
  emit nextModeChanged(nextMode);
}

QString MediaPlayer::formatTime(int t)
{
  if (t / 60 < 10)
    return QDateTime::fromTime_t(t).toUTC().toString("m:ss");
  else if (t / 60 < 60)
    return QDateTime::fromTime_t(t).toUTC().toString("mm:ss");
  else if (t / 60 / 60 < 10)
    return QDateTime::fromTime_t(t).toUTC().toString("h:mm:ss");
  else
    return QDateTime::fromTime_t(t).toUTC().toString("hh:mm:ss");
}
