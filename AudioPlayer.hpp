#pragma once
#include <QMediaPlayer>
#include "IPlaylistRadio.hpp"
#include "QmlTrack.hpp"
#include "QmlRadio.hpp"

class AudioPlayer : public QObject
{
  Q_OBJECT
public:
  explicit AudioPlayer(QObject *parent = nullptr);

  enum State {
    StatePlaying,
    StatePaused,
    StateStopped,
  };
  Q_ENUM(State)

  Q_PROPERTY(QmlTrack* currentTrack READ currentTrack NOTIFY currentTrackChanged)
  Q_PROPERTY(QmlRadio* currentRadio READ currentRadio WRITE play NOTIFY currentRadioChanged)
  Q_PROPERTY(State state READ state WRITE setState NOTIFY stateChanged)
  Q_PROPERTY(double position READ position WRITE setPosition NOTIFY positionChanged)
  Q_PROPERTY(qint64 positionMs READ positionMs WRITE setPositionMs NOTIFY positionChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(IPlaylistRadio::NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)
  Q_PROPERTY(IPlaylistRadio::LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)

  Q_PROPERTY(QString formatPosition READ formatPosition NOTIFY positionChanged) // for example, "2:58"
  Q_PROPERTY(QString formatDuration READ formatDuration NOTIFY durationChanged) // for example, "3:02"

  QmlTrack* currentTrack();
  QmlRadio* currentRadio();
  State state();
  IPlaylistRadio::NextMode nextMode();
  IPlaylistRadio::LoopMode loopMode();
  double volume();
  bool muted();
  double position();
  qint64 positionMs();
  qint64 duration();

  QString formatPosition();
  QString formatDuration();

public slots:
  void play(); // resume
  void next();
  void prev();
  void stop();
  void pause();
  void togglePause();

  void play(refRadio radio);
  void play(QmlRadio* radio);

  void setState(State state);
  void setNextMode(IPlaylistRadio::NextMode nextMode);
  void setLoopMode(IPlaylistRadio::LoopMode loopMode);
  void setVolume(double volume);
  void setMuted(bool muted);
  void setPosition(double position);
  void setPositionMs(qint64 positionMs);

signals:
  void currentTrackChanged(QmlTrack* currentTrack);
  void currentRadioChanged(QmlRadio* currentRadio);
  void stateChanged(State state);
  void nextModeChanged(IPlaylistRadio::NextMode nextMode);
  void loopModeChanged(IPlaylistRadio::LoopMode loopMode);
  void volumeChanged(double volume);
  void positionChanged(qint64 position);
  void durationChanged(qint64 duration);
  void mutedChanged(bool muted);

private slots:
  void _updateState(QMediaPlayer::State state);
  void _onMediaChanged(std::optional<QMediaContent> media);
  void _onMediaAborted();

private:
  void _setRadio(refRadio radio);
  void _unsubscribeCurrentTrack();
  void _subscribeCurrentTrack();
  void _setTrack(refTrack track);
  void _playTrack(refTrack track);
  void _resetTrack();
  QString _formatTime(int t);
  void _onMediaEnded();

  QmlTrack* _currentTrackQml;
  QmlRadio* _currentRadioQml;

  IPlaylistRadio* _playlist = nullptr;
  refRadio _radio;
  refTrack _track;

  QMediaPlayer* _player;
  State _state = StateStopped;
  IPlaylistRadio::NextMode _nextMode;
  IPlaylistRadio::LoopMode _loopMode;
  double _volume = 0.5;
};
