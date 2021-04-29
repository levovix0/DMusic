#include "ITrack.hpp"

std::optional<QString> ITrack::title()
{
  return {};
}

std::optional<QVector<refArtist> > ITrack::artists()
{
  return {};
}

std::optional<QString> ITrack::extra()
{
  return {};
}

std::optional<QString> ITrack::cover()
{
  return {};
}

std::optional<QMediaContent> ITrack::media()
{
  return {};
}

std::optional<qint64> ITrack::duration()
{
  return {};
}

std::optional<bool> ITrack::liked()
{
  return {};
}

std::optional<bool> ITrack::isExplicit()
{
  return {};
}

bool ITrack::exists()
{
  return false;
}

ID ITrack::id()
{
  return {};
}

QJsonObject ITrack::serialize()
{
  QJsonObject res;

  res["id"] = id().serialize();
  auto _title = title();
  if (_title != std::nullopt) res["title"] = _title.value();
//  auto _artists = artists();
//  if (_title != std::nullopt) res["title"] = _artists.serialize();
//  auto _extra = extra();
//  if (_title != std::nullopt) res["title"] = _extra.value();
//  auto _title = title();
//  if (_title != std::nullopt) res["title"] = _title.value();
//  auto _title = title();
//  if (_title != std::nullopt) res["title"] = _title.value();

  return res;
}
