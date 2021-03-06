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
  Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
  Q_PROPERTY(bool paused READ isPaused NOTIFY pausedChanged)
  Q_PROPERTY(QString cover READ getCover NOTIFY coverChanged)
  Q_PROPERTY(float progress READ getProgress WRITE setProgress NOTIFY progressChanged)

  Q_INVOKABLE bool isPlaying();
  Q_INVOKABLE bool isPaused();
  Q_INVOKABLE QString getCover();
  Q_INVOKABLE float getProgress();

public slots:
  void play(Track* track);
  void play(YTrack* track);
  void playYandex(int id);
  void pause_or_play();
  void pause();
  void unpause();
  void stop();
  void setProgress(float progress);

signals:
  void playingChanged();
  void pausedChanged();
  void coverChanged();
  void progressChanged();

private:
  QMediaPlayer* player;
  Track* currentTrack;
  bool m_isPaused;
  bool m_isPlaying;
  float m_progress;
};

