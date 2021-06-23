#include <cmath>
#include "AudioPlayer.hpp"
#include "Config.hpp"
#include "QDateTime"
#include "Messages.hpp"

AudioPlayer::~AudioPlayer()
{
  delete player;
}

AudioPlayer* AudioPlayer::instance = nullptr;

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), player(new QMediaPlayer(this)), _currentTrack(nullptr)
{
  instance = this;
  player->setNotifyInterval(50);
  player->setVolume(50);
  _volume = 0.5;
  _currentTrack = noneTrack;

  QObject::connect(player, &QMediaPlayer::mediaStatusChanged, [this](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) {
			if (_loopMode == Config::LoopTrack) {
        player->play();
        return;
      }

      if (_radio != nullptr) {
        if (next()) return;
      }
      stop();
    }
  });
  QObject::connect(player, &QMediaPlayer::stateChanged, [this](QMediaPlayer::State state) {
    emit stateChanged(state);
  });
  QObject::connect(player, &QMediaPlayer::mediaChanged, [this](QMediaContent const& media) {
    if (media.isNull()) emit durationChanged(0);
  });

  QObject::connect(player, &QMediaPlayer::positionChanged, this, &AudioPlayer::progressChanged);
  QObject::connect(player, &QMediaPlayer::durationChanged, this, &AudioPlayer::durationChanged);
  QObject::connect(player, &QMediaPlayer::mutedChanged, this, &AudioPlayer::mutedChanged);
}

float AudioPlayer::progress()
{
  auto duration = this->duration();
  return duration != 0? ((float)progress_ms() / (float)duration) : 0;
}

qint64 AudioPlayer::progress_ms()
{
  return player->position();
}

refTrack AudioPlayer::currentTrack()
{
  return _currentTrack;
}

Track* AudioPlayer::currentTrackPtr()
{
  return _currentTrack.get();
}

QString AudioPlayer::formatProgress()
{
  return formatTime(progress_ms() / 1000);
}

QString AudioPlayer::formatDuration()
{
  return formatTime(duration() / 1000);
}

qint64 AudioPlayer::duration()
{
  return player->media().isNull()? 0 : player->duration();
}

QMediaPlayer::State AudioPlayer::state()
{
  return player->state();
}

double AudioPlayer::volume()
{
  return _volume;
}

bool AudioPlayer::muted()
{
  return player->isMuted();
}

Config::LoopMode AudioPlayer::loopMode()
{
  return _loopMode;
}

Config::NextMode AudioPlayer::nextMode()
{
  return _nextMode;
}

void AudioPlayer::setMedia(QMediaContent media)
{
  player->stop();
  player->setMedia(media);
  player->setPosition(0);
  player->play();
}

void AudioPlayer::onMediaAborted()
{
  Messages::error(tr("Failed to load track"));
  if (_radio != nullptr) {
    _radio->markErrorCurrentTrack();
  }
  next();
}

void AudioPlayer::updatePlaylistGenerator()
{
  if (_radio != nullptr) {
    _radio->setNextMode(nextMode());
  }
}

void AudioPlayer::play(refTrack track)
{
  if (track.isNull()) return play(noneTrack);
  _radio = nullptr;
  updatePlaylistGenerator();

  _unsubscribeCurrentTrack();
  player->stop();

  _currentTrack = track;

  _subscribeCurrentTrack();

  emit currentTrackChanged(_currentTrack.get());

  player->setMedia(track->media());
  player->setPosition(0);
  player->play();
}

void AudioPlayer::play(refPlaylist playlist)
{
  if (playlist == nullptr) return play(noneTrack);

  _unsubscribeCurrentTrack();
  player->stop();

  _radio = radio(playlist, -1, nextMode());

  _currentTrack = _radio->current();
  if (_currentTrack == nullptr) return play(noneTrack);

  _subscribeCurrentTrack();

  emit currentTrackChanged(_currentTrack.get());

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
}

void AudioPlayer::play(ID id)
{
  play(id.toPlaylist());
}

void AudioPlayer::play(QString id)
{
  play(ID::deseralize(id));
}

void AudioPlayer::play(Track* track)
{
  play(refTrack(track));
}

void AudioPlayer::play(Playlist* playlist)
{
  play(refPlaylist(playlist));
}

void AudioPlayer::pause_or_play()
{
  if (state() == QMediaPlayer::PlayingState) {
    player->pause();
  } else {
    player->play();
  }
}

void AudioPlayer::pause()
{
  player->pause();
}

void AudioPlayer::play()
{
  player->play();
}

void AudioPlayer::stop()
{
  play(noneTrack);
}

bool AudioPlayer::next()
{
  _unsubscribeCurrentTrack();
  player->stop();

  if (_radio == nullptr) return false;
  _currentTrack = _radio->next();
  if (_currentTrack == nullptr) return false;

  _subscribeCurrentTrack();

  emit currentTrackChanged(_currentTrack.get());

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
  return true;
}

bool AudioPlayer::prev()
{
  if (progress_ms() > 10'000) {
    setProgress_ms(0);
    return true;
  }
  _unsubscribeCurrentTrack();
  player->stop();

  if (_radio == nullptr) return false;
  _currentTrack = _radio->prev();
  if (_currentTrack == nullptr) return false;

  _subscribeCurrentTrack();

  emit currentTrackChanged(_currentTrack.get());

  player->setMedia(_currentTrack->media());
  player->setPosition(0);
  player->play();
  return true;
}

void AudioPlayer::setProgress(float progress)
{
  player->setPosition(player->duration() * progress);
}

void AudioPlayer::setProgress_ms(int progress)
{
  player->setPosition(progress);
}

void AudioPlayer::setVolume(double volume)
{
  volume = qMin(1.0, qMax(0.0, volume));
  volume = std::round(volume * 1000) / 1000; // round to 3 decimal places
  auto vol = qRound((volume * volume) * 100); // volume^2
  if (volume > 0.01) vol = qMax(vol, 1); // minimal volume
  player->setVolume(vol);
  _volume = volume;
  emit volumeChanged(volume);
}

void AudioPlayer::setMuted(bool muted)
{
  player->setMuted(muted);
}

void AudioPlayer::setLoopMode(Config::LoopMode loopMode)
{
  _loopMode = loopMode;
  emit loopModeChanged(loopMode);
}

void AudioPlayer::setNextMode(Config::NextMode nextMode)
{
  _nextMode = nextMode;
  updatePlaylistGenerator();
  emit nextModeChanged(nextMode);
}

void AudioPlayer::_unsubscribeCurrentTrack()
{
  if (_currentTrack.isNull() || _currentTrack == noneTrack) return;
  disconnect(_currentTrack.get(), &Track::mediaChanged, this, &AudioPlayer::setMedia);
  disconnect(_currentTrack.get(), &Track::mediaAborted, this, &AudioPlayer::onMediaAborted);
}

void AudioPlayer::_subscribeCurrentTrack()
{
  if (_currentTrack.isNull() || _currentTrack == noneTrack) return;
  QObject::connect(_currentTrack.get(), &Track::mediaChanged, this, &AudioPlayer::setMedia);
  QObject::connect(_currentTrack.get(), &Track::mediaAborted, this, &AudioPlayer::onMediaAborted, Qt::QueuedConnection);
}

QString AudioPlayer::formatTime(int t)
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
