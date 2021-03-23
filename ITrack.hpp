#pragma once
#include <optional>
#include <QMediaContent>
#include "types.hpp"
#include "ID.hpp"

class ITrack : public QObject
{
  // any track can change (load) it's data on the fly
  Q_OBJECT
public:
  virtual std::optional<QString> title() = 0;
  virtual std::optional<QVector<refArtist>> artists() = 0;
  virtual std::optional<QString> extra() = 0;
  virtual std::optional<QString> cover() = 0;
  virtual std::optional<QMediaContent> media() = 0;
  virtual std::optional<qint64> duration() = 0;
  virtual std::optional<bool> liked() = 0;

  virtual bool exists(); // when false, all getters must return `none`, and emit `xAborted`

  virtual refClient client() = 0;
  virtual ID id(); // must have same client as client() returns;

public slots:
  virtual void setlike(bool liked) = 0;

signals:
  void titleChanged(std::optional<QString> title);
  void authorChanged(std::optional<QVector<refArtist>> author);
  void extraChanged(std::optional<QString> extra);
  void coverChanged(std::optional<QString> cover);
  void mediaChanged(std::optional<QMediaContent> media);
  void durationChanged(std::optional<qint64> duration);

  void titleAborted(); // title aborted to load otf
  void artistsAborted(); // artists aborted to load otf
  void extraAborted(); // extra aborted to load otf
  void coverAborted(); // cover aborted to load otf
  void mediaAborted(); // media aborted to load otf
  void durationAborted(); // duration aborted to load otf
};
