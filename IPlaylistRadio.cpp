#include "IPlaylistRadio.hpp"

IPlaylistRadio::NextMode IPlaylistRadio::nextMode()
{
  return _nextMode;
}

IPlaylistRadio::LoopMode IPlaylistRadio::loopMode()
{
  return _loopMode;
}

void IPlaylistRadio::setNextMode(IPlaylistRadio::NextMode nextMode)
{
  _nextMode = nextMode;
  emit nextModeChanged(nextMode);
}

void IPlaylistRadio::setLoopMode(IPlaylistRadio::LoopMode loopMode)
{
  _loopMode = loopMode;
  emit loopModeChanged(loopMode);
}
