#include "api.hpp"
#include "file.hpp"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

Track::~Track()
{
  switch (backend) {
  case TrackBackend::none: break;
  case TrackBackend::system: delete impl.system;
  case TrackBackend::yandex: break;
  }
}

Track::Track(QObject* parent) : QObject(parent), backend(TrackBackend::none)
{

}

Track::Track(YTrack* a, QObject* parent) : QObject(parent), backend(TrackBackend::yandex)
{
  impl.yandex = a;
}

Track::Track(QString media, QString cover, QString metadata, QObject* parent) : QObject(parent), backend(TrackBackend::system)
{
  impl.system = new SysTrack{media, cover, metadata};
}

QString Track::title()
{
  if (backend != TrackBackend::system) return "";
  if (!fs::exists(impl.system->metadata.toUtf8().data())) return "";

  QString val;
  QFile file(impl.system->metadata);
  file.open(QIODevice::ReadOnly | QIODevice::Text);
  val = file.readAll();
  file.close();
  QJsonObject doc = QJsonDocument::fromJson(val.toUtf8()).object();
  return doc["title"].toString("");
}

QString Track::author()
{
  if (backend != TrackBackend::system) return "";
  if (!fs::exists(impl.system->metadata.toUtf8().data())) return "";

  QString val;
  QFile file(impl.system->metadata);
  file.open(QIODevice::ReadOnly | QIODevice::Text);
  val = file.readAll();
  file.close();
  QJsonObject doc = QJsonDocument::fromJson(val.toUtf8()).object();
  return doc["artistsNames"].toString("");
}

QString Track::extra()
{
  if (backend != TrackBackend::system) return "";
  if (!fs::exists(impl.system->metadata.toUtf8().data())) return "";

  QString val;
  QFile file(impl.system->metadata);
  file.open(QIODevice::ReadOnly | QIODevice::Text);
  val = file.readAll();
  file.close();
  QJsonObject doc = QJsonDocument::fromJson(val.toUtf8()).object();
  return doc["extra"].toString("");
}

QString Track::cover()
{
  switch (backend) {
  case TrackBackend::none: return "qrc:resources/player/no-cover.svg";
  case TrackBackend::system: return "file:" + impl.system->cover;
  case TrackBackend::yandex: return impl.yandex->coverPath();
  }
  return "qrc:resources/player/no-cover.svg";
}

QString Track::media()
{
  switch (backend) {
  case TrackBackend::none: return "";
  case TrackBackend::system: return impl.system->media;
  case TrackBackend::yandex: return impl.yandex->soundPath();
  }
  return "";
}
