#include "ID.hpp"
#include "YandexMusic.hpp"

QString ID::serialize() const
{
  if (kind == dkNone)
    if (containerKind == dkNone)
      return toString(client) + "/" + QString::number(id);
    else
      return toString(client) + "/" + toString(containerKind) + ":" + QString::number(container) + "/" + QString::number(id);
  else
    if (containerKind == dkNone)
      return toString(client) + "/" + toString(kind) + ":" + QString::number(id);
    else
      return toString(client) + "/" + toString(containerKind) + ":" + QString::number(container) + "/" + toString(kind) + ":" + QString::number(id);
}

ID ID::deseralize(QString s)
{
  auto s1 = s.split("/");
  if (s1.size() < 2) return {};
  ID res;
  // TODO: client kind
  if (s1.size() >= 3) { // has container
    auto s2 = s1[1].split(":");
    if (s2.size() >= 2) {
      bool ok;
      res.container = s2[1].toLongLong(&ok);
      if (!ok) res.container = 0;
      // TODO: container kind
    }
    s1.removeAt(1);
  }
  auto s2 = s1[1].split(":");
  if (s2.size() >= 2) {
    bool ok;
    res.id = s2[1].toLongLong(&ok);
    if (!ok) res.id = 0;
  }
  // TODO: kind
  return res;
}

refTrack ID::toTrack() const
{
  return nullptr;
}

refPlaylist ID::toPlaylist() const
{
  return nullptr;
}
