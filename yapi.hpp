#pragma once
#include "python.hpp"
#include <api.hpp>
#include <QObject>
#include <atomic>
#include <QVariantList>
#include <QJSValue>

struct YArtist;
struct YTrack;

struct YTrack : Track
{
  Q_OBJECT
public:
  explicit YTrack(py::object track, QObject *parent = nullptr);
  ~YTrack();
  YTrack();

  PyObject* raw() { return impl.raw; }

  QString title() override;
  QString author() override;
  QString extra() override;
  QString cover() override;
  QString media() override;

  Q_INVOKABLE int id();
  Q_INVOKABLE int duration();
  Q_INVOKABLE bool available();
  Q_INVOKABLE QVector<YArtist> artists();
  Q_INVOKABLE QString coverPath();
  Q_INVOKABLE QString metadataPath();
  Q_INVOKABLE QString soundPath();

  QJsonObject jsonMetadata();
  Q_INVOKABLE QString stringMetadata();
  Q_INVOKABLE void saveMetadata();
  Q_INVOKABLE bool saveCover(int quality = 1000);
  Q_INVOKABLE void saveCover(int quality, QJSValue const& callback);

  Q_INVOKABLE bool download();
  Q_INVOKABLE void download(QJSValue const& callback);

private:
  bool loadFromDisk();
  bool loadFromPython();

  py::object impl;
  int _id;
  QString _title, _author, _extra, _cover, _media;
//  bool _noTitle, _noAuthor, _noExtra, _noCover, _noMedia;
};
inline PyObject* toPyObject(YTrack a) { Py_INCREF(a.raw()); return a.raw(); }
inline void fromPyObject(py::object const& o, YTrack*& res) { res = new YTrack(o.raw); }

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

class YClient : public QObject
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

  Q_INVOKABLE std::pair<bool, QList<YTrack*>> fetchTracks(int id);
  Q_INVOKABLE void fetchTracks(int id, QJSValue const& callback);

private:
  py::module ym; // yandex_music module
  py::module ym_request;

  py::object me; // client

  std::atomic_bool loggined;
};
