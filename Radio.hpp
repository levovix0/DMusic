#pragma once
#include "types.hpp"
#include "settings.hpp"

class Radio
{
public:
  virtual ~Radio() {}
  Radio() {}
  virtual void setNextMode(Settings::NextMode nextMode);
  virtual refTrack current();
  virtual refTrack next();
  virtual refTrack prev();

  virtual void markErrorCurrentTrack();
};
