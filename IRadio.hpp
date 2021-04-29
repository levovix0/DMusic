#pragma once
#include "ITrack.hpp"

class IRadio : public QObject
{
  Q_OBJECT
public:
  virtual std::optional<refTrack> current() = 0; // get current track
  virtual void next() = 0;        // switch to next track
  virtual void prev() = 0;        // switch to previous track
  virtual std::optional<refTrack> getNext();
  virtual std::optional<refTrack> getPrev();

  virtual bool hasCurrent();
  virtual bool hasNext();
  virtual bool hasPrevious();
};
