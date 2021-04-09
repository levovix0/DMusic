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
  virtual std::optional<QString> title();
  virtual std::optional<QVector<refArtist>> artists();
  virtual std::optional<QString> extra();
  virtual std::optional<QString> cover();
  virtual std::optional<QMediaContent> media();
  virtual std::optional<qint64> duration();
  virtual std::optional<bool> liked();
  virtual std::optional<bool> isExplicit();

  virtual bool exists(); // when false, all getters must return `none`, and emit `xAborted`

  virtual refClient client() = 0;
  virtual ID id(); // must have same client as client() returns;

public slots:
  virtual void setliked(bool liked) = 0;

  virtual void fetchInfo() {}
  virtual void fetchCover() {}
  virtual void fetchMedia() {}
  virtual void fetch() {}
  virtual void refetch() { fetch(); } // full reload from internet

signals:
  void titleChanged(std::optional<QString> title);
  void artistsChanged(std::optional<QVector<refArtist>> author);
  void extraChanged(std::optional<QString> extra);
  void coverChanged(std::optional<QString> cover);
  void mediaChanged(std::optional<QMediaContent> media);
  void durationChanged(std::optional<qint64> duration);
  void likedChanged(std::optional<bool> liked);
  void isExplicitChanged(std::optional<bool> isExplicit);

  // something aborted to load otf (for example, not exist or no internet connection)
  void titleAborted();
  void artistsAborted();
  void extraAborted();
  void coverAborted();
  void mediaAborted();
  void durationAborted();
  void likedAborted();
  void isExplicitAborted();
};
