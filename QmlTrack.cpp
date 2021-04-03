#include "QmlTrack.hpp"

QmlTrack::QmlTrack(QObject* parent) : QObject(parent)
{

}

QmlTrack::QmlTrack(const refTrack& ref, QObject* parent) : QObject(parent), ref(ref)
{

}
