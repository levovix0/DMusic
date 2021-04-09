#include "QmlTrack.hpp"
#include "utils.hpp"
#include "IArtist.hpp"

QmlTrack::QmlTrack(QObject* parent) : QObject(parent)
{

}

QmlTrack::QmlTrack(const refTrack& ref, QObject* parent) : QObject(parent)
{
  setRef(ref);
}

QString QmlTrack::title()
{
  return ref->title().value_or("");
}

QString QmlTrack::artistsStr()
{
  auto artists = ref->artists();
  if (artists == std::nullopt) return "";
  QVector<QString> names(artists->length());
  for (auto artist : artists.value()) {
    names.append(artist->name().value_or("?"));
  }
  return join(names, ", ");
}

QString QmlTrack::extra()
{
  return ref->title().value_or("");
}

QString QmlTrack::cover()
{
  return ref->cover().value_or("qrc:/resources/player/no-cover.svg");
}

QMediaContent QmlTrack::media()
{
  return ref->media().value_or(QMediaContent());
}

qint64 QmlTrack::duration()
{
  return ref->duration().value_or(0);
}

bool QmlTrack::liked()
{
  return ref->duration().value_or(false);
}

bool QmlTrack::isExplicit()
{
  return ref->isExplicit().value_or(false);
}

void QmlTrack::setRef(refTrack track)
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
