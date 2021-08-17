#pragma once
#include <atomic>
#include <QObject>
#include <QVariantList>
#include <QQmlEngine>
#include <QJSEngine>
#include <QAbstractListModel>

#include "python.hpp"
#include "api.hpp"

struct YArtist;
struct YClient;

struct YTrack : Track
{
  Q_OBJECT
public:
  YTrack(QObject* parent = nullptr);
  YTrack(qint64 id, QObject* parent = nullptr);
  YTrack(py::object obj, QObject* parent = nullptr);
  ~YTrack();

  PyObject* raw() const { return _py.raw; }

  int id() override;
  QString title() override;
  QString artistsStr() override;
  QString comment() override;
  QUrl cover() override;
  QMediaContent audio() override;
  qint64 duration() override;
  bool liked() override;
  QUrl originalUrl() override;

  bool isYandex() override { return true; }
  YTrack* toYandex() override { return this; }

  void invalidateAudio() override;

  QVector<YArtist> artists();

public slots:
  void setLiked(bool liked) override;
  void saveToDisk(bool overrideCover = false);

private:
  // getX methods don't emit xChanged
  void _getAllFromDisk();

  void _getInfoFromInternet();
  void _getLikedFromInternet();
  void _getArtistsFromInternet();
  void _getCoverFromInternet();
  void _getAudioFromInternet();
  bool _gotAllFromInternet();

  void _fetchInternet();
  void _fetchInternet(py::object _pys);

  int _id{0};
  QString _title, _comment;  // info
  QString _artists;
  QUrl _cover;
  QUrl _audio;
  bool _liked{false};
  int _duration{0};  // info

  enum class GotFrom { None, Disk, Internet };
  GotFrom _gotInfo{GotFrom::None};
  GotFrom _gotLiked{GotFrom::None};
  GotFrom _gotArtists{GotFrom::None};
  GotFrom _gotCover{GotFrom::None};
  GotFrom _gotAudio{GotFrom::None};

  py::object _py{py::none};
  bool _checkedDisk{false};
};
inline PyObject* toPyObject(YTrack const& a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YTrack*& res) { res = new YTrack(o, nullptr); }

struct YArtist : QObject
{
  Q_OBJECT
public:
  YArtist(py::object impl, QObject* parent = nullptr);
  YArtist();
  YArtist(YArtist const& copy);
  YArtist& operator=(YArtist const& copy);
  PyObject* raw() { return impl.raw; }

  int id();
  QString name();

private:
  py::object impl;
  int _id;
};
inline PyObject* toPyObject(YArtist a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YArtist& res) { res = YArtist(o.raw); }
inline void fromPyObject(py::object const& o, YArtist*& res) { res = new YArtist(o.raw); }

struct YPlaylist : QObject
{
  Q_OBJECT
public:
  YPlaylist(py::object impl, QObject* parent = nullptr);
  YPlaylist();
  PyObject* raw() const { return impl.raw; }

  Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
  Q_PROPERTY(QUrl cover READ cover WRITE setCover NOTIFY coverChanged)

  virtual QString name();
  virtual QUrl cover();
  virtual refPlaylist toPlaylist();

public slots:
  bool setName(QString name);
  bool setCover(QUrl cover);

signals:
  void nameChanged(QString name);
  void coverChanged(QUrl cover);

private:
  py::object impl;
};
inline PyObject* toPyObject(YPlaylist const& a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YPlaylist*& res) { res = new YPlaylist(o.raw); }

struct YLikedTracks : YPlaylist
{
  Q_OBJECT
public:
  YLikedTracks(QObject* parent = nullptr);

  static YLikedTracks* instance;
  static YLikedTracks* qmlInstance(QQmlEngine*, QJSEngine*);

  QString name() override;
  QUrl cover() override;
  refPlaylist toPlaylist() override;
};

struct YPlaylistsModel : QAbstractListModel
{
  Q_OBJECT
public:
  YPlaylistsModel(QObject* parent = nullptr);
  int rowCount(const QModelIndex& parent) const override;
  QVariant data(const QModelIndex& index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  QVector<YPlaylist*> playlists;
};

struct YClient : QObject
{
  Q_OBJECT
public:
  ~YClient();
  YClient(QObject *parent = nullptr);

  static YClient* instance;
  static YClient* qmlInstance(QQmlEngine*, QJSEngine*);

  Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)
  Q_PROPERTY(bool loggined READ loggined NOTIFY logginedChanged)

  bool initialized();
  bool loggined();

  refTrack track(qint64 id);

public slots:

  void init();

  QString token(QString login, QString password);
  void login(QString token);
  void login(QString token, QString proxy);

  void unlogin();

  QVector<py::object> fetchTracks(qint64 id);

  YLikedTracks* likedTracks();
  YPlaylist* playlist(int id);
  Playlist* oneTrack(qint64 id);
  YPlaylist* userDailyPlaylist();
  Playlist* userTrack(int id);
  YPlaylistsModel* homePlaylistsModel();

  void playPlaylist(YPlaylist* playlist);
  void playDownloads();

  void addUserTrack(QUrl media, QUrl cover, QString title, QString artists, QString extra);

  void searchAndPlayTrack(QString promit); //! костыль

signals:
  void initializedChanged(bool initialized);
  void logginedChanged(bool loggined);

public:
  py::module ym; // yandex_music module
  py::module ym_request;

  py::object me; // client

private:
  bool _initialized = false;
  std::atomic_bool _loggined = false;
};
