#include "api.hpp"
#include "file.hpp"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRandomGenerator>

Playlist Playlist::none;

Track::~Track()
{}

Track::Track(QObject* parent) : QObject(parent)
{}

QString Track::title()
{
  return "";
}

QString Track::author()
{
  return "";
}

QString Track::extra()
{
  return "";
}

QString Track::cover()
{
  return "qrc:resources/player/no-cover.svg";
}

QMediaContent Track::media()
{
  return {};
}

qint64 Track::duration()
{
  return 0;
}

Playlist::~Playlist()
{

}

Playlist::Playlist(QObject* parent) : QObject(parent)
{

}

refTrack Playlist::operator[](int index)
{
  return get(index);
}

refTrack Playlist::get(int index)
{
  Q_UNUSED(index)
  return nullptr;
}

Playlist::Generator Playlist::sequenceGenerator(int index)
{
  Q_UNUSED(index)
  return {[]{ return nullptr; }, []{ return nullptr; }};
}

Playlist::Generator Playlist::shuffleGenerator(int index)
{
  Q_UNUSED(index)
  return {[]{ return nullptr; }, []{ return nullptr; }};
}

Playlist::Generator Playlist::randomAccessGenerator(int index)
{
  Q_UNUSED(index)
  return {[]{ return nullptr; }, []{ return nullptr; }};
}

Playlist::Generator Playlist::generator(int index, Settings::NextMode prefered)
{
  auto avaiable = modesSupported();
  switch (prefered) {
  case Settings::NextSequence:
    if (avaiable.contains(Settings::NextSequence)) return sequenceGenerator(index);
    else if (avaiable.contains(Settings::NextShuffle)) return shuffleGenerator(index);
    else if (avaiable.contains(Settings::NextRandomAccess)) return randomAccessGenerator(index);
    break;
  case Settings::NextShuffle:
    if (avaiable.contains(Settings::NextShuffle)) return shuffleGenerator(index);
    else if (avaiable.contains(Settings::NextRandomAccess)) return randomAccessGenerator(index);
    else if (avaiable.contains(Settings::NextSequence)) return sequenceGenerator(index);
    break;
  case Settings::NextRandomAccess:
    if (avaiable.contains(Settings::NextRandomAccess)) return randomAccessGenerator(index);
    else if (avaiable.contains(Settings::NextShuffle)) return shuffleGenerator(index);
    else if (avaiable.contains(Settings::NextSequence)) return sequenceGenerator(index);
    break;
  }
  return {[]{ return nullptr; }, []{ return nullptr; }};
}

int Playlist::size()
{
  return 0;
}

DPlaylist::~DPlaylist()
{

}

DPlaylist::DPlaylist(QObject* parent) : Playlist(parent)
{

}

refTrack DPlaylist::get(int index)
{
  return {_tracks[index], this};
}

Playlist::Generator DPlaylist::sequenceGenerator(int index)
{
  if (index < 0 || index > size()) return sequenceGenerator(0);
  _lastIndex = index-1;
  return {
    [this]() -> refTrack { // next
      if (_lastIndex + 1 >= _tracks.length() || _lastIndex < -1) return nullptr;
      return get(++_lastIndex);
    },
    [this]() -> refTrack { // prev
      if (_lastIndex - 1 >= _tracks.length() || _lastIndex < 1) return nullptr;
      return get(--_lastIndex);
    }
  };
}

Playlist::Generator DPlaylist::shuffleGenerator(int index)
{
  //TODO
  return randomAccessGenerator(index);
}

Playlist::Generator DPlaylist::randomAccessGenerator(int index)
{
  Q_UNUSED(index)
  return {
    [this]() -> refTrack { // next
      auto a = get(QRandomGenerator::global()->bounded(_tracks.length() - 1));
      _history.append(a);
      if (_history.length() > _tracks.length())
        _history.erase(_history.begin(), _history.begin() + (_history.length() - _tracks.length()));
      return a;
    },
    [this]() -> refTrack { // prev
      if (_history.length() > 1) {
        auto a = _history[_history.length() - 2];
        _history.pop_back();
        return a;
      }
      return get(QRandomGenerator::global()->bounded(_tracks.length() - 1));
    }
  };
}

int DPlaylist::size()
{
  return _tracks.length();
}

void DPlaylist::add(Track* a)
{
  _tracks.append(a);
}

void DPlaylist::remove(Track* a)
{
  auto b = std::find(_tracks.begin(), _tracks.end(), a);
  if (b == _tracks.end()) return;
  _tracks.erase(b);
}

refTrack::~refTrack()
{
  //decref
}

refTrack::refTrack(Track* a)
{
  _ref = a;
  //incref
}

refTrack::refTrack(Track* a, Playlist* playlist)
{
  _ref = a;
  _attachedPlaylist = playlist;
  //incref
}

refTrack::refTrack(const refTrack& copy)
{
  _ref = copy._ref;
  _attachedPlaylist = copy._attachedPlaylist;
  //incref
}

refTrack::refTrack(const refTrack& copy, Playlist* playlist)
{
  _ref = copy._ref;
  _attachedPlaylist = playlist;
  //incref
}

refTrack refTrack::operator=(const refTrack& copy)
{
  _ref = copy._ref;
  _attachedPlaylist = copy._attachedPlaylist;
  //incref
  return *this;
}

refTrack::operator Track*()
{
  return _ref;
}

QString refTrack::title()
{
  return _ref->title();
}

QString refTrack::author()
{
  return _ref->author();
}

QString refTrack::extra()
{
  return _ref->extra();
}

QString refTrack::cover()
{
  return _ref->cover();
}

QMediaContent refTrack::media()
{
  return _ref->media();
}

qint64 refTrack::duration()
{
  return _ref->duration();
}

bool refTrack::isNone()
{
  return _ref == nullptr;
}

Track* refTrack::ref()
{
  return _ref;
}

Playlist* refTrack::attachedPlaylist()
{
  return _attachedPlaylist;
}
