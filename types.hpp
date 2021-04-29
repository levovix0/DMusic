#pragma once
#include <QSharedPointer>

class ITrack;
class IArtist;
class IPlaylist;
class IRadio;
class IPlaylistRadio;
class IClient;

using refTrack = QSharedPointer<ITrack>;
using refArtist = QSharedPointer<IArtist>;
using refPlaylist = QSharedPointer<IPlaylist>;
using refRadio = QSharedPointer<IRadio>;
using refPlaylistRadio = QSharedPointer<IPlaylistRadio>;
using refClient = QSharedPointer<IClient>;

enum DataKind : quint8 {
  dkNone = 0,
  dkTrack,
  dkArtist,
  dkPlaylist,
  dkAlbum,
};
enum ClientKind : quint8 {
  ckNone = 0,
  ckYandex,
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

inline QString toString(ClientKind a) {
  switch (a) {
  case ckNone: return "";
  case ckYandex: return "ym";
  }
  return "";
}
