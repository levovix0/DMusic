#pragma once
// Track, Artist, ...

#include <yapi.hpp>
#include <QObject>

struct SysTrack {
  QString media, cover, metadata;
};

class Track : public QObject
{
  Q_OBJECT
public:
  enum class TrackBackend: int {
    none,
    system,
    yandex,
//    soundCloud,
  };
  Q_ENUM(TrackBackend)

  ~Track();
  explicit Track(QObject *parent = nullptr);
  explicit Track(YTrack* a, QObject *parent = nullptr);
  explicit Track(QString media, QString cover, QString metadata, QObject *parent = nullptr);

public slots:
  QString mediaFile();
  QString coverFile();

signals:

private:
  union {
    SysTrack* system;
    YTrack* yandex;
//    ScTrack soundCloud;
  } impl;
  TrackBackend backend;
};
