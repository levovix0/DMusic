#include "QmlRadio.hpp"

QmlRadio::QmlRadio(QObject* parent) : QObject(parent)
{

}

QmlRadio::QmlRadio(const _refRadio& ref, QObject* parent) : QObject(parent)
{
  set(ref);
}

void QmlRadio::set(_refRadio ref)
{
  this->ref = ref;
}

_refRadio QmlRadio::get()
{
  return ref;
}
