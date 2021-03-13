#pragma once
#include <QObject>
#include <QMediaContent>

struct SysTrack {
  QString media, cover, metadata;
};

struct Track : QObject
{
  Q_OBJECT
public:
  virtual ~Track();
  explicit Track(QObject *parent = nullptr);

  Q_PROPERTY(QString title READ title NOTIFY titleChanged)
  Q_PROPERTY(QString author READ author NOTIFY authorChanged)
  Q_PROPERTY(QString extra READ extra NOTIFY extraChanged)
  Q_PROPERTY(QString cover READ cover NOTIFY coverChanged)
  Q_PROPERTY(QMediaContent media READ media NOTIFY mediaChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)

  virtual QString title();
  virtual QString author();
  virtual QString extra();
  virtual QString cover();
  virtual QMediaContent media();
  virtual qint64 duration();

public slots:

signals:
  void titleChanged(QString title);
  void authorChanged(QString author);
  void extraChanged(QString extra);
  void coverChanged(QString cover);
  void mediaChanged(QMediaContent media);
  void durationChanged(qint64 duration);
  
  void coverAborted();
  void mediaAborted();

private:
};

// TODO: client, освобождающий мусор, когда все говорят ему, что больше не используют трек
