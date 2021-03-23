#pragma once
#include "IRadio.hpp"

class IPlaylistRadio : public IRadio
{
  Q_OBJECT
public:
  enum NextMode {
    NextSequence,
    NextShuffle,
  };
  enum LoopMode {
    LoopNone,
    LoopPlaylist,
    LoopTrack,
  };

  virtual NextMode nextMode();
  virtual LoopMode loopMode();

public slots:
  virtual void setNextMode(NextMode nextMode);
  virtual void setLoopMode(LoopMode loopMode);

signals:
  void nextModeChanged(NextMode nextMode);
  void loopModeChanged(LoopMode loopMode);

protected:
  NextMode _nextMode = NextSequence;
  LoopMode _loopMode = LoopNone;
};
