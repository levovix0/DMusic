#include "QmlTrack.hpp"
#include "utils.hpp"
#include "IArtist.hpp"

QmlTrack::QmlTrack(QObject* parent) : QObject(parent)
{

}

QmlTrack::QmlTrack(const _refTrack& ref, QObject* parent) : QObject(parent)
{
  set(ref);
}

QString QmlTrack::title()
{
  if (ref.isNull()) return "";
  return ref->title().value_or("");
}

QString QmlTrack::artistsStr()
{
  if (ref.isNull()) return "";
  auto artists = ref->artists();
  if (artists == std::nullopt) return "";
  QVector<QString> names(artists->length());
  for (auto&& artist : artists.value()) {
    names.append(artist->name().value_or("?"));
  }
  return join(names, ", ");
}

QString QmlTrack::extra()
{
  if (ref.isNull()) return "";
  return ref->title().value_or("");
}

QString QmlTrack::cover()
{
  if (ref.isNull()) return "qrc:/resources/player/no-cover.svg";
  return ref->cover().value_or("qrc:/resources/player/no-cover.svg");
}

QMediaContent QmlTrack::media()
{
  if (ref.isNull()) return {};
  return ref->media().value_or(QMediaContent());
}

qint64 QmlTrack::duration()
{
  if (ref.isNull()) return 0;
  return ref->duration().value_or(0);
}

bool QmlTrack::liked()
{
  if (ref.isNull()) return false;
  return ref->duration().value_or(false);
}

bool QmlTrack::isExplicit()
{
  if (ref.isNull()) return false;
  return ref->isExplicit().value_or(false);
}

void QmlTrack::set(_refTrack track)
{
  ref = track;
  disconnect(nullptr, nullptr, this, nullptr);
  connect(ref.get(), &ITrack::titleChanged, this, &QmlTrack::titleChanged);
  connect(ref.get(), &ITrack::artistsChanged, this, &QmlTrack::artistsChanged);
  connect(ref.get(), &ITrack::extraChanged, this, &QmlTrack::extraChanged);
  connect(ref.get(), &ITrack::coverChanged, this, &QmlTrack::coverChanged);
  connect(ref.get(), &ITrack::mediaChanged, this, &QmlTrack::mediaChanged);
  connect(ref.get(), &ITrack::durationChanged, this, &QmlTrack::durationChanged);
  connect(ref.get(), &ITrack::likedChanged, this, &QmlTrack::likedChanged);
  connect(ref.get(), &ITrack::isExplicitChanged, this, &QmlTrack::isExplicitChanged);
}

_refTrack QmlTrack::get()
{
  return ref;
}
