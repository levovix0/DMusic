#pragma once
#include <QObject>
#include <QMediaContent>

struct Track : public QObject
{
  Q_OBJECT
public:
  virtual ~Track();
  explicit Track(QObject *parent = nullptr);

  Q_PROPERTY(QString idInt READ idInt NOTIFY idIntChanged)
  Q_PROPERTY(QString title READ title NOTIFY titleChanged)
  Q_PROPERTY(QString artistsStr READ artistsStr NOTIFY artistsStrChanged)
  Q_PROPERTY(QString extra READ extra NOTIFY extraChanged)
  Q_PROPERTY(QString cover READ cover NOTIFY coverChanged)
  Q_PROPERTY(QMediaContent media READ media NOTIFY mediaChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(bool liked READ liked NOTIFY likedChanged)

  virtual QString idInt();
  virtual QString title();
  virtual QString artistsStr();
  virtual QString extra();
  virtual QString cover();
  virtual QMediaContent media();
  virtual qint64 duration();
  virtual bool liked();

public slots:
  virtual void setLiked(bool liked);

signals:
  void idIntChanged(QString idInt);
  void titleChanged(QString title);
  void artistsStrChanged(QString author);
  void extraChanged(QString extra);
  void coverChanged(QString cover);
  void mediaChanged(QMediaContent media);
  void durationChanged(qint64 duration);
  void likedChanged(bool liked);

  void coverAborted();
  void mediaAborted();
};
