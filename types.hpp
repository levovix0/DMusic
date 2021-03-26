#pragma once
#include <QSharedPointer>

class ITrack;
class IArtist;
class IPlaylst;
class IRadio;
class IPlaylstRadio;
class IClient;

using refTrack = QSharedPointer<ITrack>;
using refArtist = QSharedPointer<IArtist>;
using refPlaylist = QSharedPointer<IPlaylst>;
using refRadio = QSharedPointer<IRadio>;
using refPlaylistRadio = QSharedPointer<IPlaylstRadio>;
using refClient = QSharedPointer<IClient>;

enum DataKind : quint8 {
  dkNone = 0,
  dkTrack,
  dkArtist,
  dkPlaylist,
  dkAlbum,
};

inline QString toString(DataKind a) {
  switch (a) {
  case dkNone: return "";
  case dkTrack: return "track";
  case dkArtist: return "artist";
  case dkPlaylist: return "playlist";
  case dkAlbum: return "album";
  }
  return "";
}
