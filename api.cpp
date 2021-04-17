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

Track::~Track()
{}

Track::Track(QObject* parent) : QObject(parent)
{}

QString Track::idInt()
{
  return "";
}

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
  emit coverAborted();
  return "qrc:resources/player/no-cover.svg";
}

QMediaContent Track::media()
{
  emit mediaAborted();
  return {};
}

qint64 Track::duration()
{
  return 0;
}

bool Track::liked()
{
  return false;
}

void Track::setLiked(bool)
{

}

Playlist::~Playlist()
{

}

Playlist::Playlist(QObject* parent) : QObject(parent)
{

}

refTrack_ Playlist::operator[](int index)
{
  return get(index);
}

refTrack_ Playlist::get(int index)
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

refTrack_ DPlaylist::get(int index)
{
  return {_tracks[index], this};
}

Playlist::Generator DPlaylist::sequenceGenerator(int index)
{
  if (index < -1 || index > size()) return sequenceGenerator(0);
  _currentIndex = index;
  return {
    [this]() -> refTrack_ { // next
      if (_currentIndex + 1 >= _tracks.length() || _currentIndex < -1) return nullptr;
      return get(++_currentIndex);
    },
    [this]() -> refTrack_ { // prev
      if (_currentIndex - 1 >= _tracks.length() || _currentIndex < 1) return nullptr;
      return get(--_currentIndex);
    }
  };
}

Playlist::Generator DPlaylist::shuffleGenerator(int index)
{
  if (index < 0 || index > size()) return shuffleGenerator(QRandomGenerator::global()->bounded(_tracks.length()));

  _history = _tracks;
  std::shuffle(_history.begin(), _history.end(), rnd);

  _currentIndex = _tracks.length();
  // TODO: if index track in second half of history, reverse history
  _history.append(get(index));

  auto gen = [this](refTrack_* begin, refTrack_* end) -> refTrack_ {
    // do not repeat begin..end
    auto possible = _tracks;
    for (auto it = begin; it < end; ++it) {
      possible.removeAll(*it);
    }
    if (possible.length() < 1)
      return _tracks[QRandomGenerator::global()->bounded(_tracks.length())];
    else
      return possible[QRandomGenerator::global()->bounded(possible.length())];
  };

  int half = std::floor((double)_tracks.length() / 2.0);
  for (int i = 0; i < _tracks.length(); ++i) {
    _history.append(gen(_history.end() - half, _history.end()));
  }

  return {
    [this, gen]() -> refTrack_ { // next
      if (_history.length() > _tracks.length() * 2 + 1) { // add some tracks
        // TODO
      }
      if (_history.length() < _tracks.length() * 2 + 1) { // remove some tracks
        // TODO
      }

      if (_history.length() <= 0) return nullptr;
      if (_history.length() <= 2) return _tracks.last();

      std::rotate(_history.begin(), _history.begin() + 1, _history.end()); // rotate left

      int half = std::floor((double)_tracks.length() / 2.0);
      _history.last() = gen(_history.end() - half - 1, _history.end() - 1);

      return _history[_currentIndex];
    },
    [this, gen]() -> refTrack_ { // prev
      if (_history.length() > _tracks.length() * 2 + 1) { // add some tracks
        // TODO
      }
      if (_history.length() < _tracks.length() * 2 + 1) { // remove some tracks
        // TODO
      }

      if (_history.length() <= 0) return nullptr;
      if (_history.length() <= 2) return _tracks.last();

      std::rotate(_history.rbegin(), _history.rbegin() + 1, _history.rend()); // rotate right

      int half = std::floor((double)_tracks.length() / 2.0);
      _history.first() = gen(_history.begin() + 1, _history.begin() + half + 1);

      return _history[_currentIndex];
    }
  };
}

Playlist::Generator DPlaylist::randomAccessGenerator(int index)
{
  Q_UNUSED(index)
  return {
    [this]() -> refTrack_ { // next
      auto a = get(QRandomGenerator::global()->bounded(_tracks.length()));
      _history.append(a);
      if (_history.length() > _tracks.length())
        _history.erase(_history.begin(), _history.begin() + (_history.length() - _tracks.length()));
      return a;
    },
    [this]() -> refTrack_ { // prev
      if (_history.length() > 1) {
        auto a = _history[_history.length() - 2];
        _history.pop_back();
        return a;
      }
      return get(QRandomGenerator::global()->bounded(_tracks.length()));
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

refTrack_::~refTrack_()
{
  //decref
}

refTrack_::refTrack_(Track* a)
{
  _ref = a;
  //incref
}

refTrack_::refTrack_(Track* a, Playlist* playlist)
{
  _ref = a;
  _attachedPlaylist = playlist;
  //incref
}

refTrack_::refTrack_(const refTrack_& copy)
{
  _ref = copy._ref;
  _attachedPlaylist = copy._attachedPlaylist;
  //incref
}

refTrack_::refTrack_(const refTrack_& copy, Playlist* playlist)
{
  _ref = copy._ref;
  _attachedPlaylist = playlist;
  //incref
}

refTrack_ refTrack_::operator=(const refTrack_& copy)
{
  _ref = copy._ref;
  _attachedPlaylist = copy._attachedPlaylist;
  //incref
  return *this;
}

bool refTrack_::operator==(const refTrack_& b) const
{
  return _ref == b._ref;
}

bool refTrack_::operator==(Track* b) const
{
  return _ref == b;
}

refTrack_::operator Track*()
{
  return _ref;
}

QString refTrack_::title()
{
  return _ref->title();
}

QString refTrack_::author()
{
  return _ref->author();
}

QString refTrack_::extra()
{
  return _ref->extra();
}

QString refTrack_::cover()
{
  return _ref->cover();
}

QMediaContent refTrack_::media()
{
  return _ref->media();
}

qint64 refTrack_::duration()
{
  return _ref->duration();
}

bool refTrack_::isNone()
{
  return _ref == nullptr;
}

Track* refTrack_::ref()
{
  return _ref;
}

Playlist* refTrack_::attachedPlaylist()
{
  return _attachedPlaylist;
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

QString UserTrack::author()
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
    if (s.endsWith(ids)) return QString("file:") + QDir::currentPath() + "/" + "user/" + ids + ext;
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
    if (ext != ".mp3" && ext != ".vaw" && ext != ".ogg" && ext != ".m4a") continue;
    s.chop(4);
    if (s.endsWith(ids)) return QMediaContent(QUrl(QString("file:") + QDir::currentPath() + "/" + "user/" + ids + ext));
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

  QFile::copy(media, "user/" + QString::number(id) + "." + QFileInfo(media).completeSuffix());
  if (cover != "") {
    QFile::copy(cover, "user/" + QString::number(id) + "." + QFileInfo(cover).completeSuffix());
  }
  save();
}
