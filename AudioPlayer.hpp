#pragma once
#include "QmlTrack.hpp"

class AudioPlayer : public QObject
{
  Q_OBJECT
public:
  explicit AudioPlayer(QObject *parent = nullptr);

  Q_PROPERTY(QmlTrack* currentTrack READ currentTrack NOTIFY currentTrackChanged)

  QmlTrack* currentTrack();

signals:
  void currentTrackChanged(QmlTrack* currentTrack);

private:
  QmlTrack* _currentTrackQml;
};
