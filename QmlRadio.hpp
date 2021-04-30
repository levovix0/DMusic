#pragma once
#include <QObject>
#include "IRadio.hpp"

class QmlRadio : public QObject
{
  Q_OBJECT
public:
  explicit QmlRadio(QObject* parent = nullptr);
  explicit QmlRadio(_refRadio const& ref, QObject* parent = nullptr);

  void set(_refRadio ref);
  _refRadio get();

signals:

private:
  _refRadio ref{};
};
