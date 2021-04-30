#include "_AudioPlayer.hpp"
#include <cmath>
#include <QDateTime>

_AudioPlayer::_AudioPlayer(QObject *parent) : QObject(parent), _currentTrackQml(new QmlTrack(this)), _currentRadioQml(new QmlRadio(this)), _player(new QMediaPlayer(this))
{
  _player->setVolume(50); // 50%
  _player->setNotifyInterval(50); // 50ms

  connect(_player, &QMediaPlayer::stateChanged, this, &_AudioPlayer::_updateState);
  connect(_player, &QMediaPlayer::positionChanged, this, &_AudioPlayer::positionChanged);
  connect(_player, &QMediaPlayer::durationChanged, this, &_AudioPlayer::durationChanged);

  connect(_player, &QMediaPlayer::mediaStatusChanged, [this](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::EndOfMedia) _onMediaEnded();
  });
}

QmlTrack* _AudioPlayer::currentTrack()
{
  return _currentTrackQml;
}

QmlRadio* _AudioPlayer::currentRadio()
{
  return _currentRadioQml;
}

_AudioPlayer::State _AudioPlayer::state()
{
  return _state;
}

IPlaylistRadio::NextMode _AudioPlayer::nextMode()
{
  return _nextMode;
}

IPlaylistRadio::LoopMode _AudioPlayer::loopMode()
{
  return _loopMode;
}

double _AudioPlayer::volume()
{
  return _volume;
}

bool _AudioPlayer::muted()
{
  return _player->isMuted();
}

double _AudioPlayer::position()
{
  auto duration = _player->duration();
  return duration > 0? (double)_player->position() / (double)duration : 0.0;
}

qint64 _AudioPlayer::positionMs()
{
  return _player->position();
}

qint64 _AudioPlayer::duration()
{
  return _player->duration();
}

QString _AudioPlayer::formatPosition()
{
  return _formatTime(positionMs());
}

QString _AudioPlayer::formatDuration()
{
  return _formatTime(duration());
}

void _AudioPlayer::play()
{
  _player->play();
}

void _AudioPlayer::next()
{
  _radio->next();
  if (_radio->hasCurrent())
    _playTrack(_radio->current().value());
  else
    stop();
}

void _AudioPlayer::prev()
{
  _radio->prev();
  if (_radio->hasCurrent())
    _playTrack(_radio->current().value());
  else
    stop();
}

void _AudioPlayer::stop()
{
  _player->stop();
}

void _AudioPlayer::pause()
{
  _player->pause();
}

void _AudioPlayer::togglePause()
{
  if (_state == StatePlaying) pause();
  else play();
}

void _AudioPlayer::play(_refRadio radio)
{
  _setRadio(radio);
  if (radio->hasCurrent())
    _playTrack(radio->current().value());
  else
    stop();
}

void _AudioPlayer::play(QmlRadio* radio)
{
  play(radio->get());
}

void _AudioPlayer::setState(_AudioPlayer::State state)
{
  if (_state == state) return;
  _state = state;
  switch (state) {
  case StatePlaying: play(); break;
  case StatePaused: pause(); break;
  case StateStopped: stop(); break;
  }
}

void _AudioPlayer::setNextMode(IPlaylistRadio::NextMode nextMode)
{
  _nextMode = nextMode;
  if (_playlist != nullptr) _playlist->setNextMode(nextMode);
  emit nextModeChanged(nextMode);
}

void _AudioPlayer::setLoopMode(IPlaylistRadio::LoopMode loopMode)
{
  _loopMode = loopMode;
  if (_playlist != nullptr) _playlist->setLoopMode(loopMode);
  emit loopModeChanged(loopMode);
}

void _AudioPlayer::setVolume(double volume)
{
  volume = qMin(1.0, qMax(0.0, volume));
  _volume = std::round(volume * 1000) / 1000; // round to 3 decimal places
  auto vol = qRound((_volume * _volume) * 100); // volume^2, convert 0..1 to 0..100%
  if (_volume >= 0.001) vol = qMax(vol, 1); // minimal volume
  _player->setVolume(vol);
  emit volumeChanged(_volume);
}

void _AudioPlayer::setMuted(bool muted)
{
  _player->setMuted(muted);
  emit mutedChanged(this->muted());
}

void _AudioPlayer::setPosition(double position)
{
  _player->setPosition(duration() * position);
  // _player emits `positionChanged`
}

void _AudioPlayer::setPositionMs(qint64 positionMs)
{
  _player->setPosition(positionMs);
  // _player emits `positionChanged`
}

void _AudioPlayer::_updateState(QMediaPlayer::State state)
{
  switch (state) {
  case QMediaPlayer::PlayingState: _state = StatePlaying; break;
  case QMediaPlayer::PausedState: _state = StatePaused; break;
  case QMediaPlayer::StoppedState: _state = StateStopped; break;
  }
  if (_state == StateStopped)
    _resetTrack();
  emit stateChanged(_state);
}

void _AudioPlayer::_onMediaChanged(std::optional<QMediaContent> media)
{
  if (media == std::nullopt) return _onMediaAborted();
  _player->setMedia(media.value());
  _player->play();
}

void _AudioPlayer::_onMediaAborted()
{
  next();
  // TODO: show warning
}

void _AudioPlayer::_setRadio(_refRadio radio)
{
  _radio = radio;
  _playlist = dynamic_cast<IPlaylistRadio*>(radio.get());
  _currentRadioQml->set(_radio);
  if (_playlist != nullptr) {
    _playlist->setNextMode(_nextMode);
    _playlist->setLoopMode(_loopMode);
  }
  emit currentRadioChanged(_currentRadioQml);
}

void _AudioPlayer::_unsubscribe()
{
  disconnect(nullptr, nullptr, this, SLOT(_onMediaChanged));
  disconnect(nullptr, nullptr, this, SLOT(_onMediaAborted));
}

void _AudioPlayer::_subscribeCurrentTrack()
{
  connect(_track.get(), &ITrack::mediaChanged, this, &_AudioPlayer::_onMediaChanged);
  connect(_track.get(), &ITrack::mediaAborted, this, &_AudioPlayer::_onMediaAborted);
}

void _AudioPlayer::_setTrack(_refTrack track)
{
  _unsubscribe();
  _track = track;
  _subscribeCurrentTrack();
  _currentTrackQml->set(_track);
  emit currentTrackChanged(_currentTrackQml);
}

void _AudioPlayer::_playTrack(_refTrack track)
{
  _setTrack(track);
  auto media = track->media();
  if (media != std::nullopt) {
    _player->setMedia(media.value());
    _player->play();
  }
}

void _AudioPlayer::_resetTrack()
{
  _unsubscribe();
  // TODO
  emit currentTrackChanged(_currentTrackQml);
}

QString _AudioPlayer::_formatTime(int t)
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

void _AudioPlayer::_onMediaEnded()
{
  next();
}
