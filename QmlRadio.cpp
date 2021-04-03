#include "QmlRadio.hpp"

QmlRadio::QmlRadio(QObject* parent) : QObject(parent)
{

}

QmlRadio::QmlRadio(const refRadio& ref, QObject* parent) : QObject(parent), ref(ref)
{

}
