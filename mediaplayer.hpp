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
  Q_PROPERTY(float progress READ progress WRITE setProgress NOTIFY progressChanged)
  Q_PROPERTY(qint64 progress_ms READ progress_ms WRITE setProgress_ms NOTIFY progressChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(Track* currentTrack READ currentTrack WRITE setCurrentTrack NOTIFY currentTrackChanged)
  Q_PROPERTY(QString formatProgress READ formatProgress NOTIFY progressChanged)
  Q_PROPERTY(QString formatDuration READ formatDuration NOTIFY durationChanged)

  bool playing();
  bool paused();
  float progress();
  qint64 progress_ms();

  Track* currentTrack();
  QString formatProgress();
  QString formatDuration();
  qint64 duration();

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

signals:
  void playingChanged();
  void pausedChanged();
  void progressChanged();
  void currentTrackChanged();
  void durationChanged(qint64 duration);

private:
  inline static Track noneTrack{};

  QString formatTime(int t);

  QMediaPlayer* player;
  Track* _currentTrack;
  bool m_isPaused;
  bool m_isPlaying;
};

