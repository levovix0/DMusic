#pragma once
#include <QObject>

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
  Q_PROPERTY(QString media READ media NOTIFY mediaChanged)

  virtual QString title();
  virtual QString author();
  virtual QString extra();
  virtual QString cover();
  virtual QString media();

public slots:

signals:
  void titleChanged();
  void authorChanged();
  void extraChanged();
  void coverChanged();
  void mediaChanged();

private:
};
