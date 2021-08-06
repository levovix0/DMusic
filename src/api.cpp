#include "api.hpp"

#include <QFile>
#include <QDir>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QFileDialog>
#include <QQmlEngine>
#include <QMimeDatabase>

#include "nimfs.hpp"
#include "Download.hpp"
#include "TagLib.hpp"

std::random_device rd;
std::mt19937 rnd(rd());

Playlist::~Playlist()
{

}

Playlist::Playlist(QObject* parent) : QObject(parent)
{
  qmlEngine(this)->setObjectOwnership(this, QQmlEngine::CppOwnership);
}

refTrack Playlist::operator[](int index)
{
  return get(index);
}

refTrack* Playlist::begin()
{
  return nullptr;
}

refTrack* Playlist::end()
{
  return nullptr;
}

refTrack Playlist::get(int)
{
  return nullptr;
}

refRadio radio(refPlaylist self, int index, Config::NextMode nextMode)
{
  return refRadio(new PlaylistRadio(self, index, nextMode));
}

int Playlist::size()
{
  return 0;
}

void Playlist::markErrorTrack(int)
{

}


DPlaylist::~DPlaylist()
{

}

DPlaylist::DPlaylist(QObject* parent) : Playlist(parent)
{

}

refTrack DPlaylist::get(int index)
{
  if (index >= _tracks.length()) return nullptr;
  return _tracks[index];
}

refTrack* DPlaylist::begin()
{
  return _tracks.begin();
}

refTrack* DPlaylist::end()
{
  return _tracks.end();
}

int DPlaylist::size()
{
  return _tracks.length();
}

void DPlaylist::markErrorTrack(int index)
{
  remove(index);
}

void DPlaylist::add(refTrack a)
{
  _tracks.append(a);
}

void DPlaylist::remove(int index)
{
  if (index >= _tracks.length()) return;
  _tracks.remove(index);
  emit trackRemoved(index);
}

UserTrack::UserTrack(int id, QObject* parent) : Track(parent)
{
  _id = id;
  load();
}

int UserTrack::id()
{
  return _id;
}

QMediaContent UserTrack::audio()
{
  return QMediaContent(_url);
}

QString UserTrack::title()
{
  return _title;
}

QString UserTrack::artistsStr()
{
  return _artists;
}

QString UserTrack::comment()
{
  return _comment;
}

QUrl UserTrack::cover()
{
  return _cover;
}

qint64 UserTrack::duration()
{
  return _duration;
}

bool UserTrack::liked()
{
  return _liked;
}

QUrl UserTrack::originalUrl()
{
  return _url;
}

Dir UserTrack::userDir()
{
  return Config::user_saveDir();
}

void UserTrack::save()
{
  TagLib::writeTrack(Config::user_trackFile(_id), TagLib::Data{_title, _comment, _artists, _liked, 0});
}

void UserTrack::save(const QByteArray& cover)
{
  TagLib::writeTrack(Config::user_trackFile(_id), TagLib::DataWithCover{{_title, _comment, _artists, _liked, 0}, cover, ""});
}

bool UserTrack::load()
{
  try {
    auto d = TagLib::readTrack(Config::user_trackFile(_id));

    _url = QUrl::fromLocalFile(Config::user_trackFile(_id));
    _title = d.title;
    _comment = d.comment;
    _artists = d.artists;
    _cover = {QString("data:") + d.coverMimeType + ";base64," + d.cover.toBase64()};
    _liked = d.liked;
    _duration = d.duration;

    return true;
  } catch(...) {
    return false;
  }
}

void UserTrack::add(QUrl media, QUrl cover, QString title, QString artists, QString comment)
{
  //TODO: use c++20 coroutines
  int maxId = 0;
  QStringList allFiles = userDir().entryList(QStringList{"*.mp3"}, QDir::Files, QDir::SortFlag::Name);
  for (auto& s : allFiles) {
    s.chop(4);
    maxId = qMax(maxId, s.toInt());
  }
  auto id = maxId + 1;

  auto d = new Download;
  connect(d, &Download::finished, [=](QByteArray const& data) {
    writeFile(Config::user_trackFile(id), data);

    if (cover.isEmpty()) {
      TagLib::writeTrack(Config::user_trackFile(id), TagLib::Data{title, comment, artists, false, 0});
    } else {
      auto dc = new Download;
      connect(dc, &Download::finished, [=](QByteArray const& data) {
        TagLib::writeTrack(Config::user_trackFile(id), TagLib::DataWithCover{{title, comment, artists, false, 0}, data, ""});
        dc->deleteLater();
      });
      dc->start(cover);
    }
    d->deleteLater();
  });
  d->start(media);
}

PlaylistRadio::PlaylistRadio(QObject* parent) : Radio(parent)
{}

PlaylistRadio::PlaylistRadio(refPlaylist playlist, int index, Config::NextMode nextMode, QObject* parent) : Radio(parent)
{
  this->_playlist = playlist;
  _index = index;
  if (_index < 0) {
		if (nextMode == Config::NextSequence) _index = 0;
    else _index = QRandomGenerator::global()->bounded(qMax(1, playlist->size()));
  }
  PlaylistRadio::setNextMode(nextMode);
  connect(playlist.get(), &Playlist::trackRemoved, this, &PlaylistRadio::handleTrackRemoved, Qt::DirectConnection);
}

void PlaylistRadio::setNextMode(Config::NextMode nextMode)
{
	if (_nextMode == Config::NextShuffle && nextMode == Config::NextSequence) {
    _index = _history[_index];
  }
  _nextMode = nextMode;
	if (nextMode == Config::NextShuffle) {
    _history.resize(_playlist->size());

    if (_playlist->size() != 0) {
      std::iota(_history.begin(), _history.end(), 0);
      std::shuffle(_history.begin(), _history.end(), *QRandomGenerator::global());

      if (_history.mid(_playlist->size() / 2).contains(_index))
        std::reverse(_history.begin(), _history.end());

      _history.append(_index);
    }

    _index = _playlist->size();

    for (int i = 0; i < _playlist->size(); ++i)
      _history.append(gen());
  }
}

refTrack PlaylistRadio::current()
{
	if (_nextMode == Config::NextShuffle) {
    if (_index >= _history.length()) return nullptr;
    return _playlist->get(_history[_index]);
  } else {
    return _playlist->get(_index);
  }
}

refTrack PlaylistRadio::next()
{
	if (_nextMode == Config::NextSequence) {
    if (_index + 1 >= _playlist->size() || _index < -1) return nullptr;
    return _playlist->get(++_index);
  } else {
    if (_playlist->size() == 0) {
      _history.clear();
      return nullptr;
    }
    fit();

    if (_history.size() <= 0) return nullptr;
    if (_history.size() <= 2) return _playlist->get(_playlist->size() - 1);

    std::rotate(_history.begin(), _history.begin() + 1, _history.end()); // rotate left
    _history.last() = gen();

    return _playlist->get(_history[_index]);
  }
}

refTrack PlaylistRadio::prev()
{
	if (_nextMode == Config::NextSequence) {
		if (_index - 1 >= _playlist->size() || _index < 1) return nullptr;
    return _playlist->get(--_index);
  } else {
    if (_playlist->size() == 0) {
      _history.clear();
      return nullptr;
    }
    fit();

    if (_history.size() <= 0) return nullptr;
    if (_history.size() <= 2) return _playlist->get(0);

    std::rotate(_history.rbegin(), _history.rbegin() + 1, _history.rend()); // rotate right
    _history.first() = gen();

    return _playlist->get(_history[_index]);
  }
}

refTrack PlaylistRadio::markErrorCurrentTrack()
{
	if (_nextMode == Config::NextShuffle) {
    if (_index >= _history.length()) return nullptr;
    _playlist->markErrorTrack(_history[_index]);
  } else {
    _playlist->markErrorTrack(_index);
  }
  return current();
}

void PlaylistRadio::handleTrackRemoved(int index)
{
  for (auto it = _history.begin(); it != _history.end(); ++it) {
    if (*it == index) it = _history.erase(it);
    else if (*it > index) --*it;
    _index = _playlist->size();
  }
}

int PlaylistRadio::gen()
{
  QVector<int> able(_playlist->size());
  std::iota(able.begin(), able.end(), 0);
  for (int i = _history.size() - _playlist->size() / 2; i < _history.size(); ++i)
    able.removeOne(_history[i]);
  if (able.size() < 2) return QRandomGenerator::global()->bounded(_playlist->size());
  return able[QRandomGenerator::global()->bounded(able.size())];
}

void PlaylistRadio::fit()
{
  auto n = (_playlist->size() * 2 + 1) - _history.size();
  if (n != 0) {
    // regenerate playlist
    // TODO: save and correct history
		setNextMode(Config::NextShuffle);
  }
}
