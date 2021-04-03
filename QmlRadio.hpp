#pragma once
#include <QObject>
#include "IRadio.hpp"

class QmlRadio : public QObject
{
  Q_OBJECT
public:
  explicit QmlRadio(QObject* parent = nullptr);
  explicit QmlRadio(refRadio const& ref, QObject* parent = nullptr);

  refRadio ref;
signals:

};
