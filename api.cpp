#include "api.hpp"

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

QString Track::mediaFile()
{
  switch (backend) {
  case TrackBackend::none: return "";
  case TrackBackend::system: return impl.system->media;
  case TrackBackend::yandex: return impl.yandex->soundPath();
  }
  return "";
}

QString Track::coverFile()
{
  switch (backend) {
  case TrackBackend::none: return "";
  case TrackBackend::system: return impl.system->cover;
  case TrackBackend::yandex: return impl.yandex->coverPath();
  }
  return "";
}
