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
  return {client(), 0};
}
