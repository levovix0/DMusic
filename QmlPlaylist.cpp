#include "QmlPlaylist.hpp"

QmlPlaylist::QmlPlaylist(QObject *parent) : QObject(parent)
{

}
QmlPlaylist::QmlPlaylist(const _refPlaylist& ref, QObject *parent) : QObject(parent)
{
  set(ref);
}

QString QmlPlaylist::name()
{
  if (ref.isNull()) return "";
  return ref->name().value_or("");
}

QString QmlPlaylist::description()
{
  if (ref.isNull()) return "";
  return ref->description().value_or("");
}

QString QmlPlaylist::cover()
{
  if (ref.isNull()) return "qrc:/resources/player/no-cover";
  return ref->cover().value_or("qrc:/resources/player/no-cover");
}

_refPlaylist QmlPlaylist::get()
{
  return ref;
}

void QmlPlaylist::set(_refPlaylist ref)
{
  disconnect(nullptr, nullptr, this, nullptr);
  this->ref = ref;
  connect(ref.get(), &IPlaylist::nameChanged, this, &QmlPlaylist::nameChanged);
  connect(ref.get(), &IPlaylist::descriptionChanged, this, &QmlPlaylist::descriptionChanged);
  connect(ref.get(), &IPlaylist::coverChanged, this, &QmlPlaylist::coverChanged);
}

QmlRadio* QmlPlaylist::radio(int pos, IPlaylistRadio::NextMode nextMode, IPlaylistRadio::LoopMode loopMode)
{
  return new QmlRadio(ref->radio(pos, nextMode, loopMode), this);
}
