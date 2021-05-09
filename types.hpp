#pragma once
#include <QSharedPointer>

class Track;
class Playlist;
class Radio;

using refTrack = QSharedPointer<Track>;
using refPlaylist = QSharedPointer<Playlist>;
using refRadio = QSharedPointer<Radio>;

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
