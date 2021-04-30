#pragma once

#include <api.hpp>
#include <QObject>
#include <QMediaPlayer>

class AudioPlayer : public QObject
{
  Q_OBJECT
public:
  ~AudioPlayer();
  explicit AudioPlayer(QObject *parent = nullptr);

  Q_ENUM(QMediaPlayer::State)

  Q_PROPERTY(QMediaPlayer::State state READ state NOTIFY stateChanged)
  Q_PROPERTY(float progress READ progress WRITE setProgress NOTIFY progressChanged)
  Q_PROPERTY(qint64 progress_ms READ progress_ms WRITE setProgress_ms NOTIFY progressChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(Track* currentTrack READ currentTrack WRITE setCurrentTrack NOTIFY currentTrackChanged)
  Q_PROPERTY(QString formatProgress READ formatProgress NOTIFY progressChanged)
  Q_PROPERTY(QString formatDuration READ formatDuration NOTIFY durationChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
  Q_PROPERTY(Settings::LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
  Q_PROPERTY(Settings::NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)

  float progress();
  qint64 progress_ms();

  Track* currentTrack();
  QString formatProgress();
  QString formatDuration();
  qint64 duration();
  QMediaPlayer::State state();
  double volume();
  bool muted();
  Settings::LoopMode loopMode();
  Settings::NextMode nextMode();

  inline static refTrack noneTrack{new Track()};

private slots:
  void setMedia(QMediaContent media);
  void onMediaAborted();
  void updatePlaylistGenerator();

public slots:
  void play(refTrack track);
  void play(Track* track);
  void play(Playlist* playlist);
  void play();
  void pause();
  void pause_or_play();
  void stop();

  bool next();
  bool prev();

  void setCurrentTrack(Track* v);
  void setProgress(float progress);
  void setProgress_ms(int progress);
  void setVolume(double volume);
  void setMuted(bool muted);
  void setLoopMode(Settings::LoopMode loopMode);
  void setNextMode(Settings::NextMode nextMode);

signals:
  void progressChanged(qint64 ms);
  void currentTrackChanged(Track* track);
  void durationChanged(qint64 duration);
  void stateChanged(QMediaPlayer::State state);
  void volumeChanged(double volume);
  void mutedChanged(bool muted);
  void loopModeChanged(Settings::LoopMode loopMode);
  void nextModeChanged(Settings::NextMode nextMode);

private:
  void _unsubscribeCurrentTrack();
  void _subscribeCurrentTrack();

  QString formatTime(int t);

  QMediaPlayer* player;
  refTrack _currentTrack;
  Playlist* _currentPlaylist = nullptr;
  Radio _gen;
  double _volume;
  Settings::LoopMode _loopMode;
  Settings::NextMode _nextMode;
};

