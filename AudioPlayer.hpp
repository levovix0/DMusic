#pragma once
#include <QObject>
#include <QMediaPlayer>
#include "api.hpp"
#include "ID.hpp"

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
  Q_PROPERTY(Track* currentTrack READ currentTrackPtr NOTIFY currentTrackChanged)
  Q_PROPERTY(QString formatProgress READ formatProgress NOTIFY progressChanged)
  Q_PROPERTY(QString formatDuration READ formatDuration NOTIFY durationChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
	Q_PROPERTY(Config::LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
	Q_PROPERTY(Config::NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)

  float progress();
  qint64 progress_ms();

  refTrack currentTrack();
  Track* currentTrackPtr();
  QString formatProgress();
  QString formatDuration();
  qint64 duration();
  QMediaPlayer::State state();
  double volume();
  bool muted();
	Config::LoopMode loopMode();
	Config::NextMode nextMode();

  inline static refTrack noneTrack{new Track()};

  static AudioPlayer* instance;

public slots:
  void play(refTrack track);
  void play(refPlaylist playlist);
  void play(ID id);
  void play(QString id);
  void play(Track* track);
  void play(Playlist* playlist);
  void play(); // resume
  void pause();
  void pause_or_play();
  void stop();

  bool next();
  bool prev();

  void setProgress(float progress);
  void setProgress_ms(int progress);
  void setVolume(double volume);
  void setMuted(bool muted);
	void setLoopMode(Config::LoopMode loopMode);
	void setNextMode(Config::NextMode nextMode);

signals:
  void progressChanged(qint64 ms);
  void currentTrackChanged(Track* track);
  void durationChanged(qint64 duration);
  void stateChanged(QMediaPlayer::State state);
  void volumeChanged(double volume);
  void mutedChanged(bool muted);
	void loopModeChanged(Config::LoopMode loopMode);
	void nextModeChanged(Config::NextMode nextMode);

private slots:
  void setMedia(QMediaContent media);
  void onMediaAborted();
  void updatePlaylistGenerator();

private:
  void _unsubscribeCurrentTrack();
  void _subscribeCurrentTrack();

  QString formatTime(int t);

  QMediaPlayer* player;
  refTrack _currentTrack;
  refRadio _radio;
  double _volume;
	Config::LoopMode _loopMode;
	Config::NextMode _nextMode;
};

