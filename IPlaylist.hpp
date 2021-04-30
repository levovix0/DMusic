#pragma once
#include "types.hpp"
#include "IPlaylistRadio.hpp"

class IPlaylist : public QObject
{
  Q_OBJECT
public:
  virtual void fetchInfo() {}
  virtual void refetchInfo() {}
  virtual void fetchTracks() {}
  virtual void refetchTracks() {}
  virtual void fetchCover() {}
  virtual void refetchCover() {}

  virtual std::optional<QString> name();
  virtual std::optional<QString> description();
  virtual std::optional<QString> cover();
  virtual QVector<_refTrack> tracks();

  virtual _refPlaylistRadio radio(int pos, IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone) = 0;
  virtual _refPlaylistRadio radio(IPlaylistRadio::NextMode nextMode = IPlaylistRadio::NextSequence, IPlaylistRadio::LoopMode loopMode = IPlaylistRadio::LoopNone)
  { return radio(-1, nextMode, loopMode); }

signals:
  void nameChanged();
  void descriptionChanged();
  void coverChanged();
  void tracksChanged();
};
