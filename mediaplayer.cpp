#include "mediaplayer.hpp"
#include "settings.hpp"

MediaPlayer::~MediaPlayer()
{
  delete player;
}

MediaPlayer::MediaPlayer(QObject *parent) : QObject(parent), player(new QMediaPlayer), currentTrack(nullptr), m_isPaused(false), m_isPlaying(false)
{
  player->setNotifyInterval(50);
  player->setVolume(25);

  QObject::connect(player, &QMediaPlayer::stateChanged, [this](QMediaPlayer::State state) {
    if (state == QMediaPlayer::PlayingState) {
      if (!m_isPlaying) {
        m_isPlaying = true;
        emit playingChanged();
      }
      if (m_isPaused) {
        m_isPaused = false;
        emit pausedChanged();
      }
    } else if (state == QMediaPlayer::StoppedState) {
      if (m_isPlaying) {
        m_isPlaying = false;
        emit playingChanged();
      }
      if (m_isPaused) {
        m_isPaused = false;
        emit pausedChanged();
      }
      emit coverChanged();
    } else if (state == QMediaPlayer::PausedState) {
      if (m_isPlaying) {
        m_isPlaying = false;
        emit playingChanged();
      }
      if (!m_isPaused) {
        m_isPaused = true;
        emit pausedChanged();
      }
    }
  });

  QObject::connect(player, &QMediaPlayer::positionChanged, [this](qint64 milli) {
    auto duration = player->duration();
    m_progress = duration != 0? ((float)milli / (float)duration) : 0;
    emit progressChanged();
  });
}

void MediaPlayer::play(Track* track)
{
  if (isPlaying()) {
    player->stop();
    m_isPlaying = false;
    emit playingChanged();
  }
  currentTrack = track;
  m_isPaused = false;
  emit pausedChanged();
  auto media = track->mediaFile();
  if (media != "") {
    player->setMedia(QUrl::fromLocalFile(media));
    m_isPlaying = true;
    emit playingChanged();
    player->play();
  }
  emit coverChanged();
}

void MediaPlayer::play(YTrack* track)
{
  play(new Track(track));
}

void MediaPlayer::playYandex(int id)
{
  play(new Track(Settings::ym_trackPath(id), Settings::ym_coverPath(id), Settings::ym_metadataPath(id)));
}

bool MediaPlayer::isPlaying()
{
  return currentTrack != nullptr && m_isPlaying;
}

bool MediaPlayer::isPaused()
{
  return m_isPaused;
}

QString MediaPlayer::getCover()
{
  if (isPlaying()) {
    auto cover = currentTrack->coverFile();
    return cover != ""? "file:" + cover : "resources/player/no-cover.svg";
  }
  return "resources/player/no-cover.svg";
}

float MediaPlayer::getProgress()
{
  return m_progress;
}

void MediaPlayer::pause_or_play()
{
  if (currentTrack == nullptr) return;
  if (m_isPaused) {
    m_isPaused = false;
    m_isPlaying = true;
    player->play();
  } else {
    m_isPaused = true;
    m_isPlaying = false;
    player->pause();
  }
  emit playingChanged();
  emit pausedChanged();
}

void MediaPlayer::pause()
{
  if (!m_isPaused) pause_or_play();
}

void MediaPlayer::unpause()
{
  if (m_isPaused) pause_or_play();
}

void MediaPlayer::stop()
{
  if (isPlaying()) {
    player->stop();
  }
  currentTrack = nullptr;
  m_isPaused = false;
  emit pausedChanged();
  m_isPlaying = false;
  emit playingChanged();
}

void MediaPlayer::setProgress(float progress)
{
  player->setPosition(player->duration() * progress);
  emit progressChanged();
}
