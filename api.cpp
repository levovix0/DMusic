#include "api.hpp"
#include "file.hpp"
#include <QFile>
#include <QDir>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QFileDialog>

Playlist Playlist::none;
std::random_device rd;
std::mt19937 rnd(rd());

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

refTrack Playlist::get(int)
{
  return nullptr;
}

Radio Playlist::radio(int, Settings::NextMode)
{
  return {[]{ return nullptr; }, []{ return nullptr; }, refPlaylist(this)};
}

Radio DPlaylist::radio(int index, Settings::NextMode nextMode)
{
  if (nextMode == Settings::NextMode::NextRandomAccess) nextMode = Settings::NextMode::NextShuffle; //!
  if (nextMode == Settings::NextMode::NextSequence) {
    if (index < -1 || index > size()) return radio(0, nextMode);
    _currentIndex = index;
    return {
      [this]() -> refTrack { // next
        if (_currentIndex + 1 >= _tracks.size() || _currentIndex < -1) return nullptr;
        return get(++_currentIndex);
      },
      [this]() -> refTrack { // prev
        if (_currentIndex - 1 >= _tracks.size() || _currentIndex < 1) return nullptr;
        return get(--_currentIndex);
      },
      QSharedPointer<Playlist>(this)
    };
  } else {
    if (index < 0 || index > size()) return radio(QRandomGenerator::global()->bounded(_tracks.size()), nextMode);

    _history.resize(_tracks.size());

    if (_tracks.size() != 0) {
      std::iota(_history.begin(), _history.end(), 0);
      std::shuffle(_history.begin(), _history.end(), *QRandomGenerator::global());

      if (_history.mid(_tracks.size() / 2).contains(index))
        std::reverse(_history.begin(), _history.end());

      _history.append(index);
    }
    _currentIndex = _tracks.size();

    auto gen = [this]() -> int {
      QVector<int> able(_tracks.size());
      std::iota(able.begin(), able.end(), 0);
      for (int i = _history.size() - _tracks.size() / 2; i < _history.size(); ++i)
        able.removeOne(_history[i]);
      if (able.size() < 2) return QRandomGenerator::global()->bounded(_tracks.size());
      return able[QRandomGenerator::global()->bounded(able.size())];
    };

    for (int i = 0; i < _tracks.size(); ++i)
      _history.append(gen());

    auto fit = [this, gen]() {
      auto n = (_tracks.size() * 2 + 1) - _history.size();
      if (n < 0)
        for (int i = 0; i < n; ++i) _history.pop_back();
      else if (n > 0)
        for (int i = 0; i < n; ++i) _history.append(gen());
    };

    return {
      [this, gen, fit]() -> refTrack { // next
        if (_tracks.size() == 0) {
          _history.clear();
          return nullptr;
        }
        fit();

        if (_history.size() <= 0) return nullptr;
        if (_history.size() <= 2) return _tracks.last();

        std::rotate(_history.begin(), _history.begin() + 1, _history.end()); // rotate left
        _history.last() = gen();

        return get(_history[_currentIndex]);
      },
      [this, gen, fit]() -> refTrack { // prev
        if (_tracks.size() == 0) {
          _history.clear();
          return nullptr;
        }
        fit();

        if (_history.size() <= 0) return nullptr;
        if (_history.size() <= 2) return _tracks[0];

        std::rotate(_history.rbegin(), _history.rbegin() + 1, _history.rend()); // rotate right
        _history.first() = gen();

        return get(_history[_currentIndex]);
      },
      QSharedPointer<Playlist>(this)
    };
  }
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
  return _tracks[index];
}

int DPlaylist::size()
{
  return _tracks.length();
}

void DPlaylist::add(refTrack a)
{
  _tracks.append(a);
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

QString UserTrack::cover()
{
  auto ids = QString::number(id);
  auto recoredDir = QDir("user");
  QStringList allFiles = recoredDir.entryList(QDir::Files, QDir::SortFlag::Name);
  for (auto s : allFiles) {
    auto ext = s.right(4);
    if (ext != ".png" && ext != ".jpg" && ext != ".svg") continue;
    s.chop(4);
    if (s.endsWith(ids)) return QString("file:") + QDir::cleanPath(QDir::currentPath() + "/" + "user/" + ids + ext);
  }
  emit coverAborted();
  return "qrc:resources/player/no-cover.svg";
}

QMediaContent UserTrack::media()
{
  auto ids = QString::number(id);
  auto recoredDir = QDir("user");
  QStringList allFiles = recoredDir.entryList(QDir::Files, QDir::SortFlag::Name);
  for (auto s : allFiles) {
    auto ext = s.right(4);
    if (ext != ".mp3" && ext != ".wav" && ext != ".ogg" && ext != ".m4a") continue;
    s.chop(4);
    if (s.endsWith(ids)) return QMediaContent(QUrl(QString("file:") + QDir::cleanPath(QDir::currentPath() + "/" + "user/" + ids + ext)));
  }
  emit coverAborted();
  return QMediaContent();
}

void UserTrack::save()
{
  QJsonObject info;
  info["title"] = _title;
  info["extra"] = _extra;
  info["artists"] = _artists;

  if (!QDir("user").exists()) QDir(".").mkdir("user");
  auto json = QJsonDocument(info).toJson(QJsonDocument::Compact);
  File("user/" + QString::number(id) + ".json").writeAll(json);
}

bool UserTrack::load()
{
  if (!QFile::exists("user/" + QString::number(id) + ".json")) return false;
  QJsonObject doc = File("user/" + QString::number(id) + ".json").allJson().object();

  _title = doc["title"].toString("");
  _artists = doc["artists"].toString("");
  _extra = doc["extra"].toString("");

  return true;
}

void UserTrack::setup(QString media, QString cover, QString title, QString artists, QString extra)
{
  _title = title;
  _artists = artists;
  _extra = extra;

  if (!QDir("user").exists()) QDir(".").mkdir("user");

  int maxId = 0;
  auto recoredDir = QDir("user");
  QStringList allFiles = recoredDir.entryList(QDir::Files, QDir::SortFlag::Name);
  for (auto s : allFiles) {
    if (!s.endsWith(".json")) continue;
    s.chop(5);
    maxId = qMax(maxId, s.toInt());
  }
  id = maxId + 1;

  if (media.startsWith("file://")) media.remove(0, 7);
  if (cover.startsWith("file://")) cover.remove(0, 7);
  if (media[0] == '/' && media[2] == ':') media.remove(0, 1);
  if (cover[0] == '/' && cover[2] == ':') cover.remove(0, 1);

  QFile::copy(media, "user/" + QString::number(id) + "." + media.right(3));
  if (cover != "") {
    QFile::copy(cover, "user/" + QString::number(id) + "." + cover.right(3));
  }
  save();
}
