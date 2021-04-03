#include "AudioPlayer.hpp"
#include <cmath>
#include <QDateTime>

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent), _currentTrackQml(new QmlTrack(this)), _currentRadioQml(new QmlRadio(this)), _player(new QMediaPlayer(this))
{
  _player->setVolume(50); // 50%
  _player->setNotifyInterval(50); // 50ms

  connect(_player, &QMediaPlayer::stateChanged, this, &AudioPlayer::_updateState);
  connect(_player, &QMediaPlayer::positionChanged, this, &AudioPlayer::positionChanged);
  connect(_player, &QMediaPlayer::durationChanged, this, &AudioPlayer::durationChanged);

  connect(_player, &QMediaPlayer::mediaStatusChanged, [this](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) _onMediaEnded();
  });
}

QmlTrack* AudioPlayer::currentTrack()
{
  return _currentTrackQml;
}

QmlRadio* AudioPlayer::currentRadio()
{
  return _currentRadioQml;
}

AudioPlayer::State AudioPlayer::state()
{
  return _state;
}

IPlaylistRadio::NextMode AudioPlayer::nextMode()
{
  return _nextMode;
}

IPlaylistRadio::LoopMode AudioPlayer::loopMode()
{
  return _loopMode;
}

double AudioPlayer::volume()
{
  return _volume;
}

bool AudioPlayer::muted()
{
  return _player->isMuted();
}

double AudioPlayer::position()
{
  auto duration = _player->duration();
  return duration > 0? (double)_player->position() / (double)duration : 0.0;
}

qint64 AudioPlayer::positionMs()
{
  return _player->position();
}

qint64 AudioPlayer::duration()
{
  return _player->duration();
}

QString AudioPlayer::formatPosition()
{
  return _formatTime(positionMs());
}

QString AudioPlayer::formatDuration()
{
  return _formatTime(duration());
}

void AudioPlayer::play()
{
  _player->play();
}

void AudioPlayer::next()
{
  // todo
}

void AudioPlayer::prev()
{
  // todo
}

void AudioPlayer::stop()
{
  _player->stop();
}

void AudioPlayer::pause()
{
  _player->pause();
}

void AudioPlayer::togglePause()
{
  if (_state == StatePlaying) pause();
  else play();
}

void AudioPlayer::play(refRadio radio)
{
  _setRadio(radio);
  play();
}

void AudioPlayer::play(QmlRadio* radio)
{
  play(radio->ref);
}

void AudioPlayer::setState(AudioPlayer::State state)
{
  if (_state == state) return;
  _state = state;
  switch (state) {
  case StatePlaying: play(); break;
  case StatePaused: pause(); break;
  case StateStopped: stop(); break;
  }
}

void AudioPlayer::setNextMode(IPlaylistRadio::NextMode nextMode)
{
  _nextMode = nextMode;
  emit nextModeChanged(nextMode);
}

void AudioPlayer::setLoopMode(IPlaylistRadio::LoopMode loopMode)
{
  _loopMode = loopMode;
  emit loopModeChanged(loopMode);
}

void AudioPlayer::setVolume(double volume)
{
  _volume = round(volume * 1000) / 1000; // round to 3 decimal places
  _player->setVolume(std::round(_volume * 100)); // convert 0..1 to 0..100%
  emit volumeChanged(_volume);
}

void AudioPlayer::setMuted(bool muted)
{
  _player->setMuted(muted);
  emit mutedChanged(this->muted());
}

void AudioPlayer::setPosition(double position)
{
  _player->setPosition(duration() * position);
  // _player emits `positionChanged`
}

void AudioPlayer::setPositionMs(qint64 positionMs)
{
  _player->setPosition(positionMs);
  // _player emits `positionChanged`
}

void AudioPlayer::_updateState(QMediaPlayer::State state)
{
  switch (state) {
  case QMediaPlayer::PlayingState: _state = StatePlaying; break;
  case QMediaPlayer::PausedState: _state = StatePaused; break;
  case QMediaPlayer::StoppedState: _state = StateStopped; break;
  }
  emit stateChanged(_state);
}

void AudioPlayer::_setRadio(refRadio radio)
{
  _radio = radio;
  _playlist = dynamic_cast<IPlaylistRadio*>(radio.get());
  _currentRadioQml->ref = _radio;
  emit currentRadioChanged(_currentRadioQml);
}

QString AudioPlayer::_formatTime(int t)
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

void AudioPlayer::_onMediaEnded()
{
  // do magic
}
