#include "api.hpp"
#include "file.hpp"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

Track::~Track()
{}

Track::Track(QObject* parent) : QObject(parent)
{}

QString Track::title()
{
  return "";
}

QString Track::author()
{
  return "";
}

QString Track::extra()
{
  return "";
}

QString Track::cover()
{
  return "qrc:resources/player/no-cover.svg";
}

QString Track::media()
{
  return "";
}
