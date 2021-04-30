#pragma once
#include <QVariantList>
#include "ITrack.hpp"

class QmlTrack : public QObject
{
  Q_OBJECT
public:
  explicit QmlTrack(QObject *parent = nullptr);
  explicit QmlTrack(_refTrack const& ref, QObject *parent = nullptr);

  Q_PROPERTY(QString title READ title NOTIFY titleChanged)
  Q_PROPERTY(QString artistsStr READ artistsStr NOTIFY artistsChanged)
  Q_PROPERTY(QString extra READ extra NOTIFY extraChanged)
  Q_PROPERTY(QString cover READ cover NOTIFY coverChanged)
  Q_PROPERTY(QMediaContent media READ media NOTIFY mediaChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(bool liked READ liked NOTIFY likedChanged)
  Q_PROPERTY(bool isExplicit READ isExplicit NOTIFY isExplicitChanged)

  QString title();
  QString artistsStr();
  QString extra();
  QString cover();
  QMediaContent media();
  qint64 duration();
  bool liked();
  bool isExplicit();

  void set(_refTrack track);
  _refTrack get();

signals:
  void titleChanged();
  void artistsChanged();
  void extraChanged();
  void coverChanged();
  void mediaChanged();
  void durationChanged();
  void likedChanged();
  void isExplicitChanged();

private:
  _refTrack ref{};
};

