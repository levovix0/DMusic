#include "YandexMusic.hpp"

#include <thread>
#include <functional>

#include <QGuiApplication>
#include <QMediaPlayer>

#include "file.hpp"
#include "Config.hpp"
#include "utils.hpp"
#include "AudioPlayer.hpp"
#include "TagLib.hpp"
#include "nimfs.hpp"
#include "Download.hpp"

using namespace py;

YTrack::YTrack(QObject* parent) : Track(parent)
{
}

YTrack::YTrack(qint64 id, QObject* parent) : YTrack(parent)
{
  _id = id;
}

YTrack::YTrack(object obj, QObject* parent) : YTrack(parent)
{
  _id = obj.get("id").to<qint64>();
  _fetchInternet(obj);
}

YTrack::~YTrack()
{

}

QString YTrack::title()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotInfo == GotFrom::None) _getInfoFromInternet();
  return _title;
}

QString YTrack::comment()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotInfo == GotFrom::None) _getInfoFromInternet();
  return _comment;
}

QString YTrack::artistsStr()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotArtists == GotFrom::None) _getArtistsFromInternet();
  return _artists;
}

QUrl YTrack::cover()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotCover == GotFrom::None) _getCoverFromInternet();
  return _cover;
}

QMediaContent YTrack::audio()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotAudio == GotFrom::None || _gotAudio == GotFrom::Internet) _getAudioFromInternet();
  // if got audio from internet, link may be outdated, so re-get audio from internet in all cases
  return {_audio};
}

bool YTrack::liked()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotLiked == GotFrom::None) _getLikedFromInternet();
  return _liked;
}

QUrl YTrack::originalUrl()
{
  return "https://music.yandex.ru/track/" + QString::number(_id);
}

void YTrack::invalidateAudio()
{
  _gotAudio = GotFrom::None;
  _audio = QUrl{};
  _checkedDisk = false;
  emit audioChanged(audio());
}

qint64 YTrack::duration()
{
  if (!_checkedDisk) _getAllFromDisk();
  if (_gotInfo == GotFrom::None) _getInfoFromInternet();
  return _duration;
}

int YTrack::id()
{
  return _id;
}

QVector<YArtist> YTrack::artists()
{
  _fetchInternet();
  if (_py == nullptr) return {};
  return _py.get("artists").to<QVector<YArtist>>();
}

void YTrack::setLiked(bool liked)
{
  _fetchInternet();
  if (_py == nullptr) return;
  do_async([this, liked](){
    try {
      if (liked) {
        _py.call("like");
      } else {
        _py.call("dislike");
      }
      _liked = liked;
      emit likedChanged(liked);
    } catch(std::exception& e) {
    }

    if (fileExists(Config::ym_trackFile(_id))) saveToDisk();
  });
}

void YTrack::saveToDisk(bool overrideCover)
{
  //TODO: use c++20 coroutines
  auto filename = Config::ym_trackFile(_id);

  if (!fileExists(filename)) {
    auto d = new Download;
    connect(d, &Download::finished, [d, this, filename](QByteArray data) {
      writeFile(filename, data);

      auto dc = new Download;
      connect(dc, &Download::finished, [dc, this, filename](QByteArray data) {
        TagLib::writeTrack(filename, TagLib::DataWithCover{{_title, _comment, _artists, _liked, 0}, data, ""});
        _checkedDisk = false;
        dc->deleteLater();
      });
      dc->start(_cover);

      d->deleteLater();
    });
    d->start(_audio);
  } else {
    if (overrideCover) {
      auto dc = new Download;
      connect(dc, &Download::finished, [dc, this, filename](QByteArray data) {
        TagLib::writeTrack(filename, TagLib::DataWithCover{{_title, _comment, _artists, _liked, 0}, data, ""});
        _checkedDisk = false;
        dc->deleteLater();
      });
      dc->start(_cover);
    } else {
      TagLib::writeTrack(filename, TagLib::Data{_title, _comment, _artists, _liked, 0});
      _checkedDisk = false;
    }
  }
}

void YTrack::_getAllFromDisk()
{
  _checkedDisk = true;
  try {
    auto d = TagLib::readTrack(Config::ym_trackFile(_id));

    _audio = QUrl::fromLocalFile(Config::ym_trackFile(_id));
    _title = d.title;
    _comment = d.comment;
    _artists = d.artists;
    _cover = {QString("data:") + d.coverMimeType + ";base64," + d.cover.toBase64()};
    _liked = d.liked;
    _duration = d.duration;

    _gotAudio = GotFrom::Disk;
    _gotInfo = GotFrom::Disk;
    _gotArtists = GotFrom::Disk;
    _gotLiked = GotFrom::Disk;
    _gotCover = GotFrom::Disk;
  } catch(...) {}
}

void YTrack::_getInfoFromInternet()
{
  _gotInfo = GotFrom::Internet;
  _fetchInternet();
  if (_py == nullptr) return;

  try {
    _title = _py.get("title").to<QString>();
    _comment = _py.get("version").to<QString>();
    _duration = _py.get("duration_ms").to<int>();
  }
  catch (std::exception& e) {
  }
  if (Config::ym_saveAllTracks() && _gotAllFromInternet()) saveToDisk();
}

void YTrack::_getLikedFromInternet()
{
  _gotLiked = GotFrom::Internet;
  _fetchInternet();
  if (_py == nullptr) return;
  try {
    auto ult = _py.get("client").call("users_likes_tracks").get("tracks_ids");
    _liked = false;
    for (auto&& p : ult) {
      if (!p.contains(":")) continue;
      if (p.call("split", ":")[0].to<int>() == _id) {
        _liked = true;
        break;
      }
    }
  } catch (std::exception& e) {
  }
  if (Config::ym_saveAllTracks() && _gotAllFromInternet()) saveToDisk();
}

void YTrack::_getArtistsFromInternet()
{
  _gotArtists = GotFrom::Internet;
  try {
    auto artists = this->artists();
    QVector<QString> artists_str;
    for (auto&& artist : artists) artists_str.append(artist.name());
    _artists = join(artists_str, ", ");
  } catch (std::exception& e) {
  }
  if (Config::ym_saveAllTracks() && _gotAllFromInternet()) saveToDisk();
}

void YTrack::_getCoverFromInternet()
{
  _gotCover = GotFrom::Internet;
  _fetchInternet();
  if (_py == nullptr) return;
  try {
    auto a = _py.get("cover_uri").to<QString>();
    if (a == "") throw std::exception();
    a = "http://" + a;
    a.truncate(a.length() - 2);
    a += "m" + toString(Config::ym_coverQuality());
    _cover = QUrl{a};
  } catch (std::exception& e) {
    // OK
    _cover = QUrl{"qrc:/resources/player/no-cover.svg"};
    emit coverAborted(e.what());
  }
  if (Config::ym_saveAllTracks() && _gotAllFromInternet()) saveToDisk();
}

void YTrack::_getAudioFromInternet()
{
  _gotAudio = GotFrom::Internet;
  _fetchInternet();
  if (_py == nullptr) return;
  try {
    _audio = QUrl(_py.call("get_download_info")[0].call("get_direct_link").to<QString>());
  } catch (std::exception& e) {
    emit audioAborted(e.what());
  }
  if (Config::ym_saveAllTracks() && _gotAllFromInternet()) saveToDisk();
}

bool YTrack::_gotAllFromInternet()
{
  return _gotInfo == GotFrom::Internet && _gotLiked == GotFrom::Internet && _gotArtists == GotFrom::Internet
      && _gotCover == GotFrom::Internet && _gotAudio == GotFrom::Internet;
}

void YTrack::_fetchInternet()
{
  if (_py != py::none) return;
  try {
    auto _pys = YClient::instance->fetchTracks(_id);
    if (_pys.empty()) throw std::runtime_error("empty result");
    _py = _pys[0];
  } catch (std::exception& e) {
    _py = nullptr;
  }
}

void YTrack::_fetchInternet(object _pys)
{
  _py = (_pys == none || _pys == nullptr)? nullptr : _pys;
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
  return {tr("qrc:/resources/covers/favorite.svg")};
}

refPlaylist YLikedTracks::toPlaylist()
{
  DPlaylist* res = new DPlaylist(this);
  try {
    if (!YClient::instance->initialized()) throw std::runtime_error(tr("Yandex music api is not initialized").toStdString());

    // add user-added and liked tracks
    for (auto&& s : Config::user_saveDir().entryList(QStringList{"*.mp3"}, QDir::Files, QDir::SortFlag::Name)) {
      s.chop(4);
      auto r = refTrack(new UserTrack(s.toInt()));
      if (r->liked())
        res->add(r);
    }

    auto a = YClient::instance->me.call("users_likes_tracks").get("tracks_ids");
    for (auto&& p : a) {
      if (!p.contains(":")) continue;
      res->add(refTrack(new YTrack(p.call("split", ":")[0].to<int>(), YClient::instance)));
    }
  } catch (std::exception& e) {
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
    emit initializedChanged(false);
  }
}

QString YClient::token(QString login, QString password)
{
  if (!initialized()) return "";
  try {
    return ym.get("Client")().call("generate_token_by_username_and_password", {login, password}).to<QString>();
  } catch (std::exception& e) {
  }
  return "";
}

void YClient::login(QString token)
{
  // if (!initialized()) return;
  // if (token == "") return;
  // do_async([this, token](){
  //   try {
  //     me = ym.call("Client", token);

  //     _loggined = true;
  //     emit logginedChanged(_loggined);
  //   }  catch (std::exception& e) {
  //     _loggined = false;
  //     emit logginedChanged(_loggined);
  //   }
  // });
}
void YClient::login(QString token, QString proxy)
{
  // if (!initialized()) return;
  // if (token == "") return;
  // if (proxy == "") {
  //   login(token);
  //   return;
  // }
  // do_async([this, token, proxy](){
  //   try {
  //     std::map<std::string, object> kwargs;
  //     kwargs["proxy_url"] = proxy;
  //     object req = ym_request.call("Request", std::initializer_list<object>{}, kwargs);
  //     kwargs.clear();
  //     kwargs["request"] = req;
  //     me = ym.call("Client", token);

  //     _loggined = true;
  //     emit logginedChanged(_loggined);
  //   }  catch (std::exception& e) {
  //     _loggined = false;
  //     emit logginedChanged(_loggined);
  //   }
  // });
}

void YClient::unlogin()
{
  _loggined = false;
  emit logginedChanged(_loggined);
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
  }
  return nullptr;
}

Playlist* YClient::oneTrack(int id)
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
  }
  return nullptr;
}

Playlist* YClient::userTrack(int id)
{
  DPlaylist* res = new DPlaylist(this);
  res->add(refTrack(new UserTrack(id)));
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
      }
    }
  } catch (py::error& e) {
  }
  return res;
}

void YClient::playPlaylist(Playlist* playlist)
{
  if (playlist == nullptr) return;
  AudioPlayer::instance->play(refPlaylist{playlist});
}

void YClient::playYPlaylist(YPlaylist* playlist)
{
  if (playlist == nullptr) return;
  AudioPlayer::instance->play(playlist->toPlaylist());
}

void YClient::playDownloads()
{
  DPlaylist* res = new DPlaylist(this);
  for (auto&& s : Config::user_saveDir().entryList(QStringList{"*.mp3"}, QDir::Files, QDir::SortFlag::Name)) {
    s.chop(4);
    res->add(refTrack(new UserTrack(s.toInt())));
  }
  if (initialized()) {
    for (auto&& s : Config::ym_saveDir().entryList(QStringList{"*.mp3"}, QDir::Files, QDir::SortFlag::Name)) {
      s.chop(4);
      res->add(track(s.toInt()));
    }
  }
  AudioPlayer::instance->play(refPlaylist(res));
}

void YClient::addUserTrack(QUrl media, QUrl cover, QString title, QString artists, QString extra)
{
  UserTrack::add(media, cover, title, artists, extra);
}

void YClient::searchAndPlayTrack(QString promit)
{
  if (!initialized()) return;
  try {
    auto search = me.call("search", promit);
    if (search.get("tracks")) {
      auto t = search.get("tracks").get("results")[0];

      DPlaylist* res = new DPlaylist(this);
      res->add(track(t.get("id").to<int>()));
      AudioPlayer::instance->play(res);
    }
  } catch (std::exception& e) {
  }
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
