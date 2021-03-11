#include "mediaplayer.hpp"
#include "settings.hpp"
#include "QDateTime"

MediaPlayer::~MediaPlayer()
{
  delete player;
}

MediaPlayer::MediaPlayer(QObject *parent) : QObject(parent), player(new QMediaPlayer), _currentTrack(nullptr), m_isPaused(false), m_isPlaying(false)
{
  player->setNotifyInterval(50);
  player->setVolume(25);
  _currentTrack = &noneTrack;

  QObject::connect(player, &QMediaPlayer::stateChanged, [this](QMediaPlayer::State state) {
    if (state == QMediaPlayer::PlayingState) {
      m_isPlaying = true;
      emit playingChanged();
      m_isPaused = false;
      emit pausedChanged();
    }
    else if (state == QMediaPlayer::StoppedState) {
      m_isPlaying = false;
      emit playingChanged();
      m_isPaused = false;
      emit pausedChanged();
      
      setProgress_ms(0);
      if (_currentTrack != &noneTrack) delete _currentTrack;
      _currentTrack = &noneTrack;
      emit currentTrackChanged();
    }
    else if (state == QMediaPlayer::PausedState) {
      m_isPlaying = false;
      emit playingChanged();
      m_isPaused = true;
      emit pausedChanged();
    }
  });

  QObject::connect(player, &QMediaPlayer::positionChanged, this, &MediaPlayer::progressChanged);
  QObject::connect(player, &QMediaPlayer::durationChanged, this, &MediaPlayer::durationChanged);
}

void MediaPlayer::play(Track* track)
{
  if (track == nullptr) return play(&noneTrack);
  if (playing()) {
    player->stop();
  }
  if (_currentTrack != &noneTrack) delete _currentTrack;
  _currentTrack = track;
  emit currentTrackChanged();
  
  //TODO: подгрузка на лету
  auto media = track->media();
  if (media != "") {
    player->setMedia(QUrl::fromLocalFile(media));
    player->play();
  }
}

void MediaPlayer::play(YTrack* track)
{
  play(new Track(track));
}

void MediaPlayer::playYandex(int id)
{
  play(new Track(Settings::ym_trackPath(id), Settings::ym_coverPath(id), Settings::ym_metadataPath(id)));
}

bool MediaPlayer::playing()
{
  return m_isPlaying;
}

bool MediaPlayer::paused()
{
  return player->state() == QMediaPlayer::PausedState;
}

float MediaPlayer::progress()
{
  auto duration = player->duration();
  return duration != 0? ((float)player->position() / (float)duration) : 0;
}

int MediaPlayer::progress_ms()
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

QString MediaPlayer::formatEnd()
{
  return formatTime(player->duration() / 1000);
}

void MediaPlayer::pause_or_play()
{
  if (playing()) {
    player->pause();
  } else {
    player->play();
  }
}

void MediaPlayer::pause()
{
  player->pause();
}

void MediaPlayer::unpause()
{
  player->play();
}

void MediaPlayer::stop()
{
  play(&noneTrack);
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

QString MediaPlayer::formatTime(int t)
{
  if (t / 60 < 10)
    return QDateTime::fromTime_t(t).toUTC().toString("m:ss");
  else if (t / 60 >= 10)
    return QDateTime::fromTime_t(t).toUTC().toString("mm:ss");
  else if (t / 60 / 60 >= 1)
    return QDateTime::fromTime_t(t).toUTC().toString("h:mm:ss");
  else
    return QDateTime::fromTime_t(t).toUTC().toString("hh:mm:ss");
}
