#pragma once
#include <atomic>
#include <QObject>
#include <QVariantList>
#include <QJSValue>
#include "python.hpp"
#include "api.hpp"

struct YArtist;
struct YClient;

struct YTrack : Track
{
  Q_OBJECT
public:
  YTrack(qint64 id, YClient* client);
  YTrack(py::object obj, YClient* client);
  ~YTrack();
  YTrack(QObject* parent = nullptr);

  PyObject* raw() const { return _py.raw; }

  QString idInt() override;
  QString title() override;
  QString artistsStr() override;
  QString extra() override;
  QString cover() override;
  QMediaContent media() override;
  qint64 duration() override;
  bool liked() override;

  qint64 id();
  bool available();
  QVector<YArtist> artists();
  QString coverPath();
  QString metadataPath();
  QString mediaPath();

  QJsonObject jsonMetadata();
  QString stringMetadata();
  void saveMetadata();

  YClient* _client;

public slots:
  void setLiked(bool liked) override;

private:
  bool _loadFromDisk();
  
  void _fetchYandex();
  void _fetchYandex(py::object _pys);
  void _downloadCover();
  void _downloadMedia();
  void _checkLiked();

  QString _coverUrl();

  py::object _py;
  QMutex _mtx = QMutex(QMutex::Recursive);
  qint64 _id;
  QString _title, _author, _extra, _cover, _media;
  qint64 _duration;
  bool _liked = false;
  QVector<qint64> _artists;
  bool _noTitle = false, _noAuthor = false, _noExtra = false, _noCover = false, _noMedia = false;
  bool _hasLiked = false;
  bool _relativePathToCover = true;
  bool _checkedDisk = false;
};
inline PyObject* toPyObject(YTrack const& a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YTrack*& res) { res = new YTrack(o, nullptr); }

struct YArtist : QObject
{
  Q_OBJECT
public:
  YArtist(py::object impl, QObject *parent = nullptr);
  YArtist();
  YArtist(YArtist const& copy);
  YArtist& operator=(YArtist const& copy);
  PyObject* raw() { return impl.raw; }

  int id();
  QString name();
  QString coverPath();
  QString metadataPath();

  QJsonObject jsonMetadata();
  QString stringMetadata();
  void saveMetadata();
  bool saveCover(int quality = 1000);
  void saveCover(int quality, QJSValue const& callback);

private:
  py::object impl;
  int _id;
};
inline PyObject* toPyObject(YArtist a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YArtist& res) { res = YArtist(o.raw); }
inline void fromPyObject(py::object const& o, YArtist*& res) { res = new YArtist(o.raw); }

struct YClient : QObject
{
	Q_OBJECT
public:
  ~YClient();
  YClient(QObject *parent = nullptr);

  Q_INVOKABLE bool isLoggined();

  Q_INVOKABLE QString token(QString login, QString password);
  Q_INVOKABLE bool login(QString token);
  Q_INVOKABLE void login(QString token, QJSValue const& callback);
  Q_INVOKABLE bool loginViaProxy(QString token, QString proxy);
  Q_INVOKABLE void loginViaProxy(QString token, QString proxy, QJSValue const& callback);

  QVector<py::object> fetchTracks(qint64 id);
  Q_INVOKABLE std::pair<bool, QList<YTrack*>> fetchYTracks(qint64 id);
  Q_INVOKABLE void fetchYTracks(qint64 id, QJSValue const& callback);

  refTrack track(qint64 id);

  static inline YClient* instance = nullptr;

public slots:
  Playlist* likedTracks();
  Playlist* playlist(int id);
  Playlist* oneTrack(qint64 id);
  Playlist* userDailyPlaylist();
  Playlist* userTrack(int id);
  Playlist* downloadsPlaylist();

  void addUserTrack(QString media, QString cover, QString title, QString artists, QString extra);

private:
  py::module ym; // yandex_music module
  py::module ym_request;

  py::object me; // client

  std::atomic_bool loggined;
};
