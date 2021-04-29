#include "QmlRadio.hpp"

QmlRadio::QmlRadio(QObject* parent) : QObject(parent)
{

}

QmlRadio::QmlRadio(const refRadio& ref, QObject* parent) : QObject(parent)
{
  set(ref);
}

void QmlRadio::set(refRadio ref)
{
  this->ref = ref;
}

refRadio QmlRadio::get()
{
  return ref;
}
