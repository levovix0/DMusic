#pragma once

#include <QObject>

class MediaPlayer : public QObject
{
  Q_OBJECT
public:
  explicit MediaPlayer(QObject *parent = nullptr);

signals:

};

