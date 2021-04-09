#pragma once
#include <QObject>

class IArtist : public QObject
{
  Q_OBJECT
public:
  explicit IArtist(QObject *parent = nullptr);

  virtual std::optional<QString> name();

signals:
  void nameChanged(std::optional<QString> name);
  void nameAborted();
};
