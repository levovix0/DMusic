#pragma once
#include "types.hpp"

struct ID
{
  qint64 id = 0;
  ClientKind client = ckNone;
  DataKind kind = dkNone;

  qint64 container = 0;
  DataKind containerKind = dkNone;

  QString serialize() const;
  static ID deseralize(QString s);

  refTrack toTrack() const;
  refPlaylist toPlaylist() const;
};

