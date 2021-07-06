#include <thread>
#include <functional>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QGuiApplication>
#include <QMediaPlayer>
#include "yapi.hpp"
#include "file.hpp"
#include "Config.hpp"
#include "utils.hpp"
#include "Messages.hpp"
#include "AudioPlayer.hpp"

using namespace py;

YTrack::YTrack(qint64 id, QObject* parent) : Track(parent)
{
  _id = id;
}

YTrack::YTrack(object obj, QObject* parent) : Track(parent)
{
  _id = obj.get("id").to<qint64>();
  _fetchYandex(obj);
}

YTrack::~YTrack()
{

}

YTrack::YTrack(QObject* parent) : Track(parent)
{

}

QString YTrack::idStr()
{
  return QString::number(_id);
}

QString YTrack::title()
{
  if (!_checkedDisk) _loadFromDisk();
  if (_title.isEmpty() && !_noTitle) {
    do_async([this](){ _fetchYandex(); saveMetadata(); });
  }
  return _title;
}

QString YTrack::artistsStr()
{
  if (!_checkedDisk) _loadFromDisk();
  if (_author.isEmpty() && !_noAuthor) {
    do_async([this](){ _fetchYandex(); saveMetadata(); });
  }
  return _author;
}

QString YTrack::extra()
{
  if (!_checkedDisk) _loadFromDisk();
  if (_extra.isEmpty() && !_noExtra) {
    do_async([this](){ _fetchYandex(); saveMetadata(); });
  }
  return _extra;
}

QUrl YTrack::cover()
{
  if (!_checkedDisk) _loadFromDisk();
	if (Config::ym_saveCover()) {
    if (_cover.isEmpty()) {
      if (!_noCover) _downloadCover(); // async
      else emit coverAborted(tr("No cover"));
      return {"qrc:resources/player/no-cover.svg"};
    }
		auto s = _relativePathToCover? Config::ym_saveDir().sub(_cover) : _cover;
    if (!fileExists(s)) {
      if (_relativePathToCover)
        _downloadCover(); // async
      return {"qrc:resources/player/no-cover.svg"};
    }
    return "file:" + s;
  } else {
    if (_py == none) do_async([this](){
      _fetchYandex();
      if (_py == none || _py == nullptr || !_py.has("cover_uri")) return;
      emit coverChanged(_coverUrl());
    });
    else
      return _coverUrl();
  }
  return {"qrc:resources/player/no-cover.svg"};
}

QMediaContent YTrack::media()
{
  if (!_checkedDisk) _loadFromDisk();
	if (Config::ym_downloadMedia()) {
    if (_media.isEmpty()) {
      if (!_noMedia) do_async([this](){ QMutexLocker lock(&_mediaMtx); _downloadMedia(); });
      else {
        Messages::error(tr("Failed to get Yandex.Music track media (id: %1)").arg(_id), tr("No media"));
        emit mediaAborted(tr("No media"));
      }
      return {};
    }
    if (mediaFile().exists()) return QMediaContent(QUrl(mediaFile().fs.fileName()));
    else {
      Messages::message(tr("media file not found (id: %1), it will be re-downloaded").arg(_id), tr("File %1 not exist").arg(mediaFile().fs.fileName()));
      do_async([this](){ QMutexLocker lock(&_mediaMtx); _downloadMedia(); });
      return {};
    }
  } else {
    if (_py == none) do_async([this](){
      _fetchYandex();
      if (_py == none || _py == nullptr || !_py.has("cover_uri")) {
        emit mediaAborted(tr("Failed to fetch Yandex.Music track (id: %1)").arg(_id));
      } else {
        emit mediaChanged(QMediaContent(QUrl(_py.call("get_download_info")[0].call("get_direct_link").to<QString>())));
      }
    });
    else
      return QMediaContent(QUrl(_py.call("get_download_info")[0].call("get_direct_link").to<QString>()));
  }
  return {};
}

qint64 YTrack::duration()
{
  if (!_checkedDisk) _loadFromDisk();
  if (_duration == 0 && !_noMedia) {
    do_async([this](){ _fetchYandex(); saveMetadata(); });
  }
  return _duration;
}

bool YTrack::liked()
{
  if (!_checkedDisk) _loadFromDisk();
  if (!_hasLiked) {
    do_async([this](){ QMutexLocker lock(&_likedMtx); _checkLiked(); saveMetadata(); });
  }
  return _liked;
}

int YTrack::id()
{
  return _id;
}

bool YTrack::available()
{
  //TODO: check _py is not nil
  return _py.get("available").to<bool>();
}

QVector<YArtist> YTrack::artists()
{
  //TODO: check _py is not nil
  return _py.get("artists").to<QVector<YArtist>>();
}

File YTrack::coverFile()
{
	return Config::ym_cover(id());
}

File YTrack::metadataFile()
{
	return Config::ym_metadata(id());
}

File YTrack::mediaFile()
{
	return Config::ym_media(id());
}

QJsonObject YTrack::jsonMetadata()
{
  QJsonObject info;
  info["hasTitle"] = !_noTitle;
  info["hasAuthor"] = !_noAuthor;
  info["hasExtra"] = !_noExtra;
  info["hasCover"] = !_noCover;
  info["hasMedia"] = !_noMedia;

  info["title"] = _title;
  info["extra"] = _extra;
  info["artistsNames"] = _author;
  info["artists"] = toQJsonArray(_artists);
  info["cover"] = _cover;
  info["relativePathToCover"] = _relativePathToCover;
  info["duration"] = _duration;
  if (_hasLiked) info["liked"] = _liked;
  return info;
}

QString YTrack::stringMetadata()
{
  auto json = QJsonDocument(jsonMetadata()).toJson(QJsonDocument::Compact);
  return json.data();
}

void YTrack::saveMetadata()
{
	if (!Config::ym_saveInfo()) return;
  if (_id <= 0) return;
  metadataFile().writeAll(jsonMetadata());
}

void YTrack::setLiked(bool liked)
{
  do_async([this, liked](){
    QMutexLocker lock(&_likedMtx);
    _fetchYandex();
    try {
      if (liked) {
        _py.call("like");
      } else {
        _py.call("dislike");
      }
      _liked = liked;
      emit likedChanged(liked);
    } catch(std::exception& e) {
      if (liked) Messages::error(tr("Failed to like track"), e.what());
      else Messages::error(tr("Failed to unlike track"), e.what());
    }

    saveMetadata();
  });
}

bool YTrack::_loadFromDisk()
{
  _checkedDisk = true;
//	if (!Config::ym_saveInfo()) return false;
  if (_id <= 0) return false;
  auto metadata = metadataFile();
  if (!metadata.exists()) return false;

  QJsonObject doc = metadata.allJson().object();

  _noTitle = !doc["hasTitle"].toBool(true);
  _noAuthor = !doc["hasAuthor"].toBool(true);
  _noExtra = !doc["hasExtra"].toBool(true);
  _noCover = !doc["hasCover"].toBool(true);
  _noMedia = !doc["hasMedia"].toBool(true);

  _title = doc["title"].toString("");
  _author = doc["artistsNames"].toString("");
  _extra = doc["extra"].toString("");
  _cover = doc["cover"].toString("");
  _relativePathToCover = doc["relativePathToCover"].toBool(true);
  _media = _noMedia? "" : QString::number(_id) + ".mp3";

  auto liked = doc["liked"];
  if (liked.isBool()) _hasLiked = true;
  _liked = liked.toBool(false);

  if (!doc["duration"].isDouble() && !_noMedia) {
    //TODO: load duration from media and save data to file. use taglib
    _duration = 0;
    do_async([this](){ _fetchYandex(); saveMetadata(); });
  } else {
    _duration = doc["duration"].toInt();
  }

  return true;
}

void YTrack::_fetchYandex()
{
  QMutexLocker lock(&_fetchMtx);
  if (_py != py::none) return;
  auto _pys = YClient::instance->fetchTracks(_id);
  if (_pys.empty()) {
    _fetchYandex(none);
  } else {
    _fetchYandex(_pys[0]);
  }
}

void YTrack::_fetchYandex(object _pys)
{
  bool needUnlock = _fetchMtx.tryLock();
  if (_py != py::none) return;
  try {
    if (_pys == none || _pys == nullptr) {
      _py = nullptr;
      _title = "";
      _author = "";
      _extra = "";
      _cover = "";
      _media = "";
      _duration = 0;
      _noTitle = true;
      _noAuthor = true;
      _noExtra = true;
      _noCover = true;
      _noMedia = true;
      _liked = false;
    } else {
      _py = _pys;

      _title = _py.get("title").to<QString>();
      _noTitle = _title.isEmpty();
      emit titleChanged(_title);

      auto artists_py = _py.get("artists").to<QVector<py::object>>();
      QVector<QString> artists_str;
      artists_str.reserve(artists_py.length());
      for (auto&& e : artists_py) {
        artists_str.append(e.get("name").to<QString>());
        _artists.append(e.get("id").to<qint64>());
      }
      _author = join(artists_str, ", ");
      _noAuthor = _author.isEmpty();
      emit artistsStrChanged(_author);

      _extra = _py.get("version").to<QString>();
      _noExtra = _extra.isEmpty();
      emit extraChanged(_extra);

      _duration = _py.get("duration_ms").to<qint64>();
      emit durationChanged(_duration);

      saveMetadata();
    }
  } catch (std::exception& e) {
    Messages::error(tr("Failed to load Yandex.Music track (id: %1)").arg(_id), e.what());
  }
  if (needUnlock) _fetchMtx.unlock();
}

void YTrack::_downloadCover()
{
  _fetchYandex();
  if (_py == none || _py == nullptr) {
    emit coverAborted(tr("Null python object"));
    return;
  }
  try {
    _py.call("download_cover", std::initializer_list<object>{coverFile().fs.fileName(), Config::ym_coverQuality()});
    _cover = QString::number(_id) + ".png";
    emit coverChanged(cover());
  } catch (std::exception& e) {
    _noCover = true;
    emit coverAborted(e.what());
  }
  saveMetadata();
}

void YTrack::_downloadMedia()
{
  _fetchYandex();
  if (_py == none || _py == nullptr) {
    emit mediaAborted(tr("Null python object"));
    return;
  }
  try {
    _py.call("download", mediaFile().fs.fileName());
    _media = QString::number(_id) + ".mp3";
    emit mediaChanged(media());
  } catch (std::exception& e) {
    _noCover = true;
    emit mediaAborted(e.what());
  }
  saveMetadata();
}

void YTrack::_checkLiked()
{
  _fetchYandex();
  if (_py == none || _py == nullptr) return;
  try {
    auto ult = _py.get("client").call("users_likes_tracks").get("tracks_ids");
    bool liked = false;
    for (auto&& p : ult) {
      if (!p.contains(":")) continue;
      if (p.call("split", ":")[0].to<int>() == _id) {
        liked = true;
        break;
      }
    }
    if (liked != _liked) {
      _liked = liked;
      emit likedChanged(_liked);
    }
  }  catch (std::exception& e) {
    Messages::error(tr("Failed to check like state of track", e.what()));
  }
}

QString YTrack::_coverUrl()
{
  if (_py == none || _py == nullptr || !_py.has("cover_uri")) return "";
  auto a = "http://" + _py.get("cover_uri").to<QString>();
  a.remove(a.length() - 2, 2);
	a += "m" + toString(Config::ym_coverQuality());
  return a;
}


YArtist::YArtist(object impl, QObject* parent) : QObject(parent)
{
  this->impl = impl;
  _id = impl.get("id").to<int>();
}

YArtist::YArtist()
{

}

YArtist::YArtist(const YArtist& copy) : QObject(nullptr), impl(copy.impl), _id(copy._id)
{

}

YArtist& YArtist::operator=(const YArtist& copy)
{
  impl = copy.impl;
  _id = copy._id;
  return *this;
}

int YArtist::id()
{
  return _id;
}

QString YArtist::name()
{
  return impl.get("name").to<QString>();
}

QString YArtist::coverPath()
{
	return Config::ym_artistCover(id()).fs.fileName();
}

QString YArtist::metadataPath()
{
	return Config::ym_artistMetadata(id()).fs.fileName();
}

QJsonObject YArtist::jsonMetadata()
{
  QJsonObject info;
  info["id"] = id();
  info["name"] = name();
  info["cover"] = coverPath();
  return info;
}

QString YArtist::stringMetadata()
{
  auto json = QJsonDocument(jsonMetadata()).toJson(QJsonDocument::Compact);
  return json.data();
}

void YArtist::saveMetadata()
{
  File(metadataPath()).writeAll(jsonMetadata());
}

bool YArtist::saveCover(int quality)
{
  QString size = QString::number(quality) + "x" + QString::number(quality);
  try {
    impl.call("download_og_image", std::initializer_list<object>{coverPath(), size});
    return true;
  } catch (std::exception& e) {
    return false;
  }
}


YPlaylist::YPlaylist(py::object impl, QObject* parent) : QObject(parent), impl(impl)
{

}

YPlaylist::YPlaylist()
{

}

QString YPlaylist::name()
{
  return impl.get("title").to<QString>();
}

QUrl YPlaylist::cover()
{
  try {
    auto a = "http://" + impl.get("cover").get("uri").to<QString>();
		return QUrl(a.replace("%%", "m" + toString(Config::ym_coverQuality())));
  } catch (py::error& e) {
    return QUrl("qrc:resources/player/no-cover.svg");
  }
}

refPlaylist YPlaylist::toPlaylist()
{
  DPlaylist* res = new DPlaylist(this);
  try {
    auto a = impl.call("fetch_tracks");
    for (auto&& p : a) {
      if (!p.has("id")) continue;
      res->add(refTrack(new YTrack(p.get("id").to<int>(), YClient::instance)));
    }
  } catch (std::exception& e) {
    Messages::error(tr("Failed to convert Yandex.Music playlist to list of tracks"), e.what());
  }
  return refPlaylist(res);
}

bool YPlaylist::setName(QString name)
{
  Q_UNUSED(name)
  // TODO
  return false;
}

bool YPlaylist::setCover(QUrl cover)
{
  Q_UNUSED(cover)
  // TODO
  return false;
}

YLikedTracks::YLikedTracks(QObject* parent) : YPlaylist(py::none, parent)
{

}

YLikedTracks* YLikedTracks::instance = new YLikedTracks;

YLikedTracks* YLikedTracks::qmlInstance(QQmlEngine*, QJSEngine*)
{
  return instance;
}

QString YLikedTracks::name()
{
  return tr("Favorites");
}

QUrl YLikedTracks::cover()
{
  return QUrl("qrc:/resources/covers/like.png");
}

refPlaylist YLikedTracks::toPlaylist()
{
  DPlaylist* res = new DPlaylist(this);
  try {
    if (!YClient::instance->initialized()) throw std::runtime_error(tr("Yandex music api is not initialized").toStdString());
    auto a = YClient::instance->me.call("users_likes_tracks").get("tracks_ids");
    for (auto&& p : a) {
      if (!p.contains(":")) continue;
      res->add(refTrack(new YTrack(p.call("split", ":")[0].to<int>(), YClient::instance)));
    }
  } catch (std::exception& e) {
    Messages::error(tr("Failed to load Yandex.Music user liked tracks"), e.what());
  }
  return refPlaylist(res);
}


YClient::~YClient()
{
  if (instance == this) instance = nullptr;
}

YClient::YClient(QObject *parent) : QObject(parent)
{
  instance = this;
}

YClient* YClient::instance = new YClient;

YClient* YClient::qmlInstance(QQmlEngine*, QJSEngine*)
{
  return instance;
}

bool YClient::initialized()
{
  return _initialized;
}

refTrack YClient::track(qint64 id)
{
  return refTrack(new YTrack(id, this));
}

bool YClient::loggined()
{
  return _loggined;
}

void YClient::init()
{
  if (_initialized) return;
  try {
    ym = module("yandex_music", true);
    ym_request = ym/"utils"/"request";
    ym.get("Client").set("notice_displayed", true);
    _initialized = true;
    emit initializedChanged(true);
  } catch (py::error& e) {
    Messages::error(tr("Failed to initialize yandex music client"), e.what());
    emit initializedChanged(false);
  }
}

QString YClient::token(QString login, QString password)
{
  if (!initialized()) return "";
  return ym.call("generate_token_by_username_and_password", {login, password}).to<QString>();
}

void YClient::login(QString token)
{
  if (!initialized()) return;
  if (token == "") return;
  do_async([this, token](){
    try {
      me = ym.call("Client", token);

      _loggined = true;
      emit logginedChanged(_loggined);
    }  catch (std::exception& e) {
      _loggined = false;
      emit logginedChanged(_loggined);
      Messages::error(tr("Failed to login to Yandex.Music"), e.what());
    }
  });
}
void YClient::login(QString token, QString proxy)
{
  if (!initialized()) return;
  if (token == "") return;
  if (proxy == "") {
    login(token);
    return;
  }
  do_async([this, token, proxy](){
    try {
      std::map<std::string, object> kwargs;
      kwargs["proxy_url"] = proxy;
      object req = ym_request.call("Request", std::initializer_list<object>{}, kwargs);
      kwargs.clear();
      kwargs["request"] = req;
      me = ym.call("Client", token);

      _loggined = true;
      emit logginedChanged(_loggined);
    }  catch (std::exception& e) {
      _loggined = false;
      emit logginedChanged(_loggined);
      Messages::error(tr("Failed to login to Yandex.Music"), e.what());
    }
  });
}

QVector<object> YClient::fetchTracks(qint64 id)
{
  if (!initialized()) return {};
  QVector<py::object> tracks;
  try {
    tracks = me.call("tracks", std::vector<object>{id}).to<QVector<py::object>>();
  } catch (...) {}
  return tracks;
}

YLikedTracks* YClient::likedTracks()
{
  return YLikedTracks::instance;
}

YPlaylist* YClient::playlist(int id)
{
  if (id == 3) return likedTracks();
  if (!initialized()) return nullptr;
  try {
    return new YPlaylist(me.call("playlists_list", me.get("me").get("account").get("uid").to<QString>() + ":" + QString::number(id))[0]);
  } catch (py::error& e) {
    Messages::error(tr("Failed to load Yandex.Music playlist (id: %1)").arg(id), e.what());
  }
  return nullptr;
}

Playlist* YClient::oneTrack(qint64 id)
{
  DPlaylist* res = new DPlaylist(this);
  if (!initialized()) return res;
  res->add(track(id));
  return res;
}

YPlaylist* YClient::userDailyPlaylist()
{
  if (!initialized()) return nullptr;
  try {
    auto ppb = me.call("landing", std::vector<object>{"personalplaylists"}).get("blocks")[0];
    return new YPlaylist(ppb.get("entities")[0].get("data").get("data"));
  } catch (py::error& e) {
    Messages::error(tr("Failed to load Yandex.Music daily playlist"), e.what());
  }
  return nullptr;
}

Playlist* YClient::userTrack(int id)
{
  DPlaylist* res = new DPlaylist(this);
  res->add(refTrack(new UserTrack(id)));
  return res;
}

Playlist* YClient::downloadsPlaylist()
{
  DPlaylist* res = new DPlaylist(this);
  if (!initialized()) return res;
  for (auto&& s : Config::ym_saveDir().entryList(QDir::Files, QDir::SortFlag::Name)) {
    if (!s.endsWith(".json")) continue;
    s.chop(5);
    res->add(track(s.toInt()));
  }
  for (auto&& s : Config::user_saveDir().entryList(QDir::Files, QDir::SortFlag::Name)) {
    if (!s.endsWith(".json")) continue;
    try {
      s.chop(5);
      res->add(refTrack(new UserTrack(s.toInt())));
    }  catch (...) {}
  }
  return res;
}

YPlaylistsModel* YClient::homePlaylistsModel()
{
  auto res = new YPlaylistsModel(this);
  if (!initialized()) return res;
  res->playlists.append(likedTracks());
  try {
    for (auto&& p : me.call("landing", std::vector<object>{"personalplaylists"}).get("blocks")[0].get("entities")) {
      try {
        res->playlists.append(new YPlaylist(p.get("data").get("data")));
      } catch (py::error& e) {
        Messages::error(tr("Failed to load one of Yandex.Music smart playlists"), e.what());
      }
    }
  } catch (py::error& e) {
    Messages::error(tr("Failed to load Yandex.Music smart playlists"), e.what());
  }
  return res;
}

void YClient::playPlaylist(YPlaylist* playlist)
{
  if (playlist == nullptr) return;
  AudioPlayer::instance->play(playlist->toPlaylist());
}

void YClient::addUserTrack(QUrl media, QUrl cover, QString title, QString artists, QString extra)
{
  UserTrack().setup(media, cover, title, artists, extra);
}

YPlaylistsModel::YPlaylistsModel(QObject* parent) : QAbstractListModel(parent)
{

}

int YPlaylistsModel::rowCount(const QModelIndex&) const
{
  return playlists.length();
}

QVariant YPlaylistsModel::data(const QModelIndex& index, int) const
{
  if (index.row() >= playlists.length()) return QVariant::Invalid;
  QVariant res;
  res.setValue(playlists[index.row()]);
  return res;
}


QHash<int, QByteArray> YPlaylistsModel::roleNames() const
{
  static QHash<int, QByteArray>* pHash = nullptr;
  if (!pHash) {
      pHash = new QHash<int, QByteArray>;
      (*pHash)[Qt::UserRole + 1] = "element";
  }
  return *pHash;
}
