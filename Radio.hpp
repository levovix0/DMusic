#pragma once
#include "types.hpp"
#include "Config.hpp"

class Radio
{
public:
  virtual ~Radio() {}
  Radio() {}
	virtual void setNextMode(Config::NextMode nextMode);
  virtual refTrack current();
  virtual refTrack next();
  virtual refTrack prev();

  virtual void markErrorCurrentTrack();
};
