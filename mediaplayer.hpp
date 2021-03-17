#pragma once

#include <api.hpp>
#include <QObject>
#include <QMediaPlayer>

class MediaPlayer : public QObject
{
  Q_OBJECT
public:
  ~MediaPlayer();
  explicit MediaPlayer(QObject *parent = nullptr);
  
  Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
  Q_PROPERTY(bool paused READ paused NOTIFY pausedChanged)
  Q_PROPERTY(QMediaPlayer::State state READ state NOTIFY stateChanged)
  Q_PROPERTY(float progress READ progress WRITE setProgress NOTIFY progressChanged)
  Q_PROPERTY(qint64 progress_ms READ progress_ms WRITE setProgress_ms NOTIFY progressChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(Track* currentTrack READ currentTrack WRITE setCurrentTrack NOTIFY currentTrackChanged)
  Q_PROPERTY(QString formatProgress READ formatProgress NOTIFY progressChanged)
  Q_PROPERTY(QString formatDuration READ formatDuration NOTIFY durationChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)

  bool playing();
  bool paused();
  float progress();
  qint64 progress_ms();

  Track* currentTrack();
  QString formatProgress();
  QString formatDuration();
  qint64 duration();
  QMediaPlayer::State state();
  double volume();
  bool muted();

  inline static Track noneTrack{};

private slots:
  void setMedia(QMediaContent media);

public slots:
  void play(Track* track);

  void pause_or_play();
  void pause();
  void unpause();
  void stop();

  void setCurrentTrack(Track* v);
  void setProgress(float progress);
  void setProgress_ms(int progress);
  void setVolume(double volume);
  void setMuted(bool muted);

signals:
  void playingChanged();
  void pausedChanged();
  void progressChanged(qint64 ms);
  void currentTrackChanged(Track* track);
  void durationChanged(qint64 duration);
  void stateChanged(QMediaPlayer::State state);
  void volumeChanged(double volume);
  void mutedChanged(bool muted);

private:

  QString formatTime(int t);

  QMediaPlayer* player;
  Track* _currentTrack;
  bool m_isPaused;
  bool m_isPlaying;
  double _volume;
};

