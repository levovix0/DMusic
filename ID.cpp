#include "ID.hpp"
#include "yapi.hpp"

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
  if (kind != dkTrack) return nullptr;
  if (containerKind != dkNone) return nullptr; // TODO
  if (client == ckYandex) {
    if (YClient::instance == nullptr) return nullptr;
    return YClient::instance->track(id);
  }
  if (client == ckNone)
    return refTrack(new UserTrack(id));
  return nullptr;
}

refPlaylist ID::toPlaylist() const
{
  if (containerKind != dkNone) return nullptr; // TODO
  if (kind == dkTrack) {
    if (client == ckYandex) {
      if (YClient::instance == nullptr) return nullptr;
      return refPlaylist(YClient::instance->oneTrack(id));
    }
    if (client == ckNone) {
      auto playlist = new DPlaylist;
      playlist->add(refTrack(new UserTrack(id)));
      return refPlaylist(playlist);
    }
  }
  else if (kind == dkPlaylist) {
    if (client == ckYandex) {
      if (YClient::instance == nullptr) return nullptr;
      if (id == -1) return YClient::instance->userDailyPlaylist()->toPlaylist();
      return refPlaylist(YClient::instance->playlist(id));
    }
    if (client == ckNone) {
      if (YClient::instance == nullptr) return nullptr;
      return refPlaylist(YClient::instance->downloadsPlaylist());
      // TODO
    }
  }
  return nullptr;
}
