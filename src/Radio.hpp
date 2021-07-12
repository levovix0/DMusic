#pragma once
#include "types.hpp"
#include "Config.hpp"

class Radio : public QObject
{
  Q_OBJECT
public:
  virtual ~Radio() {}
  Radio(QObject* parent = nullptr) : QObject(parent) {}
	virtual void setNextMode(Config::NextMode nextMode);
  virtual refTrack current();
  virtual refTrack next();
  virtual refTrack prev();

  virtual refTrack markErrorCurrentTrack();
};
