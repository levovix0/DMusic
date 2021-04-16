#pragma once
#include "python.hpp"

#include <api.hpp>
#include <QObject>
#include <atomic>
#include <QVariantList>
#include <QJSValue>

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
  QString author() override;
  QString extra() override;
  QString cover() override;
  QMediaContent media() override; //TODO: скачивать параллельно, через c++, или вообще возвращать ссылку
  qint64 duration() override;
  bool liked() override;

  Q_INVOKABLE qint64 id();
  Q_INVOKABLE bool available();
  Q_INVOKABLE QVector<YArtist> artists();
  Q_INVOKABLE QString coverPath();
  Q_INVOKABLE QString metadataPath();
  Q_INVOKABLE QString mediaPath();

  QJsonObject jsonMetadata();
  Q_INVOKABLE QString stringMetadata();
  Q_INVOKABLE void saveMetadata();

  YClient* _client;

public slots:
  void setLiked(bool liked) override;

private:
  bool _loadFromDisk();
  
  void _fetchYandex();
  void _fetchYandex(py::object _pys);
  void _downloadCover();
  void _downloadMedia();

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

  Q_INVOKABLE int id();
  Q_INVOKABLE QString name();
  Q_INVOKABLE QString coverPath();
  Q_INVOKABLE QString metadataPath();

  QJsonObject jsonMetadata();
  Q_INVOKABLE QString stringMetadata();
  Q_INVOKABLE void saveMetadata();
  Q_INVOKABLE bool saveCover(int quality = 1000);
  Q_INVOKABLE void saveCover(int quality, QJSValue const& callback);

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
  YClient(QObject *parent = nullptr);
  YClient(YClient const& copy);
  YClient& operator=(YClient const& copy);
  ~YClient();

  Q_INVOKABLE bool isLoggined();

  Q_INVOKABLE QString token(QString login, QString password);
  Q_INVOKABLE bool login(QString token);
  Q_INVOKABLE void login(QString token, QJSValue const& callback);
  Q_INVOKABLE bool loginViaProxy(QString token, QString proxy);
  Q_INVOKABLE void loginViaProxy(QString token, QString proxy, QJSValue const& callback);

  QVector<py::object> fetchTracks(qint64 id);
  Q_INVOKABLE std::pair<bool, QList<YTrack*>> fetchYTracks(qint64 id);
  Q_INVOKABLE void fetchYTracks(qint64 id, QJSValue const& callback);

public slots:
  Playlist* likedTracks();
  Playlist* playlist(int id);
  Playlist* track(qint64 id);
  Playlist* downloadsPlaylist();

private:
  py::module ym; // yandex_music module
  py::module ym_request;

  py::object me; // client

  std::atomic_bool loggined;
};
