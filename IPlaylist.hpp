#pragma once
#include "types.hpp"
#include "IPlaylistRadio.hpp"

class IPlaylist : public QObject
{
  Q_OBJECT
public:
  virtual refPlaylistRadio radio(int pos, IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone) = 0;
  virtual refPlaylistRadio radio(IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone)
  { return radio(-1, nextMode, loopMode); }

  void fetchInfo() {}
  void refetchInfo() {}
  void fetchTracks() {}
  void refetchTracks() {}
  void fetchCover() {}
  void refetchCover() {}

  QVector<refTrack> tracks();

signals:
  void dataChanged();
};
