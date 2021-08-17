#include "Track.hpp"
#include <QQmlEngine>

Track::~Track()
{}

Track::Track(QObject* parent) : QObject(parent)
{
  qmlEngine(this)->setObjectOwnership(this, QQmlEngine::CppOwnership);
}

int Track::id()
{
  return 0;
}

QString Track::title()
{
  return "";
}

QString Track::artistsStr()
{
  return "";
}

QString Track::comment()
{
  return "";
}

QUrl Track::cover()
{
  emit coverAborted(tr("Empty track"));
  return {"qrc:resources/player/no-cover.svg"};
}

QMediaContent Track::audio()
{
  emit audioAborted(tr("Empty track"));
  return {};
}

qint64 Track::duration()
{
  return 0;
}

bool Track::liked()
{
  return false;
}

QUrl Track::originalUrl()
{
  return {};
}

void Track::invalidateAudio()
{
  emit audioAborted(tr("Empty track"));
}

void Track::setLiked(bool)
{

}

