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
  Q_PROPERTY(float progress_ms READ progress_ms WRITE setProgress_ms NOTIFY progressChanged)
  Q_PROPERTY(Track* currentTrack READ currentTrack WRITE setCurrentTrack NOTIFY currentTrackChanged)
  Q_PROPERTY(QString formatProgress READ formatProgress NOTIFY progressChanged)
  Q_PROPERTY(QString formatEnd READ formatEnd NOTIFY durationChanged)

  bool playing();
  bool paused();
  float progress();
  int progress_ms();

  Track* currentTrack();
  QString formatProgress();
  QString formatEnd();

public slots:
  void play(Track* track);
  void play(YTrack* track);
  void playYandex(int id);

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
  void durationChanged();

private:
  inline static Track noneTrack{};

  QString formatTime(int t);

  QMediaPlayer* player;
  Track* _currentTrack;
  bool m_isPaused;
  bool m_isPlaying;
};

