#pragma once
#include "types.hpp"

class IPlaylist : public QObject
{
  Q_OBJECT
public:
  virtual refPlaylistRadio radio() = 0;

signals:
  void dataChanged();
};
