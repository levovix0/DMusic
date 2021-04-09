#pragma once
#include "types.hpp"

class IClient : public QObject
{
  Q_OBJECT
public:
  virtual QString identity() = 0; // for example, "yandex"
  virtual QString name() = 0; // for example, tr("Yandex")

  virtual QVector<refPlaylist> userPlaylists();
  virtual refPlaylist favorites();
  virtual QVector<refPlaylist> recomendationPlaylists();
};
