#include "Track.hpp"
#include <QQmlEngine>

Track::~Track()
{}

Track::Track(QObject* parent) : QObject(parent)
{
  qmlEngine(this)->setObjectOwnership(this, QQmlEngine::CppOwnership);
}

QString Track::idStr()
{
  return "";
}

QString Track::title()
{
  return "";
}

QString Track::artistsStr()
{
  return "";
}

QString Track::extra()
{
  return "";
}

QUrl Track::cover()
{
  emit coverAborted();
  return {"qrc:resources/player/no-cover.svg"};
}

QMediaContent Track::media()
{
  emit mediaAborted();
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

void Track::setLiked(bool)
{

}

