#pragma once
#include "types.hpp"

class IPlaylist : public QObject
{
  Q_OBJECT
public:
  virtual refPlaylistRadio radio(int pos) = 0;
  virtual refPlaylistRadio radio() { return radio(0); }

signals:
  void dataChanged();
};
