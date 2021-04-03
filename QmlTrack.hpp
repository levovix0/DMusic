#pragma once
#include "ITrack.hpp"

class QmlTrack : public QObject
{
  Q_OBJECT
public:
  explicit QmlTrack(QObject *parent = nullptr);
  explicit QmlTrack(refTrack const& ref, QObject *parent = nullptr);

  refTrack ref;
signals:

};

