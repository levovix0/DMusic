#pragma once
#include "ITrack.hpp"

class QmlTrack : public QObject
{
  Q_OBJECT
public:
  explicit QmlTrack(refTrack const& ref, QObject *parent = nullptr);

  refTrack ref;
signals:

};

