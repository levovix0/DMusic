#pragma once
#include "ITrack.hpp"

class IRadio : public QObject
{
  Q_OBJECT
public:
  virtual refTrack current() = 0; // get current track
  virtual void next() = 0;        // goto next track
  virtual void previous() = 0;    // goto previous track

  virtual bool hasCurrent();
  virtual bool hasNext() = 0;
  virtual bool hasPrevious() = 0;
};
