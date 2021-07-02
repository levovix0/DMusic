#include "api.hpp"
#include "file.hpp"
#include <QFile>
#include <QDir>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QFileDialog>
#include <QQmlEngine>

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
  this->id = id;
  load();
}

QString UserTrack::title()
{
  return _title;
}

QString UserTrack::artistsStr()
{
  return _artists;
}

QString UserTrack::extra()
{
  return _extra;
}

QUrl UserTrack::cover()
{
  auto ids = QString::number(id);
  if (userDir().file(ids + ".png").exists()) return userDir().qurl(ids + ".png");
  if (userDir().file(ids + ".jpg").exists()) return userDir().qurl(ids + ".jpg");
  if (userDir().file(ids + ".svg").exists()) return userDir().qurl(ids + ".svg");
  emit coverAborted();
  return {"qrc:resources/player/no-cover.svg"};
}

QMediaContent UserTrack::media()
{
  auto ids = QString::number(id);
  if (userDir().file(ids + ".mp3").exists()) return userDir().qurl(ids + ".mp3");
  if (userDir().file(ids + ".wav").exists()) return userDir().qurl(ids + ".wav");
  if (userDir().file(ids + ".ogg").exists()) return userDir().qurl(ids + ".ogg");
  if (userDir().file(ids + ".m4a").exists()) return userDir().qurl(ids + ".m4a");
  emit coverAborted();
  return QMediaContent();
}

Dir UserTrack::userDir()
{
  return Config::user_saveDir();
}

void UserTrack::save()
{
  QJsonObject info;
  info["title"] = _title;
  info["extra"] = _extra;
  info["artists"] = _artists;

  auto json = QJsonDocument(info).toJson(QJsonDocument::Compact);
  userDir().file(QString::number(id) + ".json").writeAll(json);
}

bool UserTrack::load()
{
  if (!userDir().file(QString::number(id) + ".json").exists()) return false;
  QJsonObject doc = userDir().file(QString::number(id) + ".json").allJson().object();

  _title = doc["title"].toString("");
  _artists = doc["artists"].toString("");
  _extra = doc["extra"].toString("");

  return true;
}

void UserTrack::setup(QUrl media, QUrl cover, QString title, QString artists, QString extra)
{
  _title = title;
  _artists = artists;
  _extra = extra;

  int maxId = 0;
  QStringList allFiles = userDir().entryList(QDir::Files, QDir::SortFlag::Name);
  for (auto& s : allFiles) {
    if (!s.endsWith(".json")) continue;
    try {
      s.chop(5);
      maxId = qMax(maxId, s.toInt());
    }  catch (...) {}
  }
  id = maxId + 1;

  QFile::copy(media.toLocalFile(), (userDir() / (QString::number(id) + "." + media.toLocalFile().right(3))).path());
  if (!cover.isEmpty()) {
    QFile::copy(cover.toLocalFile(), (userDir() / (QString::number(id) + "." + cover.toLocalFile().right(3))).path());
  }
  save();
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
