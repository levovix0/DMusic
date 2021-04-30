#pragma once
#include <QObject>
#include <QMediaContent>
#include <functional>
#include <settings.hpp>
#include <Track.hpp>
#include <types.hpp>

class Playlist;

struct Radio
{
  std::function<refTrack()> next;
  std::function<refTrack()> prev;
  refPlaylist playlist;
};

class Playlist : public QObject
{
  Q_OBJECT
public:
  virtual ~Playlist();
  Playlist(QObject* parent = nullptr);

  static Playlist none;

  refTrack operator[](int index);

  virtual refTrack get(int index);
  virtual Radio radio(int index = -1, Settings::NextMode nextMode = Settings::NextSequence);

  virtual int size(); // -1 means infinity or not determined
};

class DPlaylist : public Playlist
{
  Q_OBJECT
public:
  ~DPlaylist();
  DPlaylist(QObject* parent = nullptr);

  refTrack get(int index) override;
  Radio radio(int index = -1, Settings::NextMode nextMode = Settings::NextSequence) override;

  int size() override;

public slots:
  void add(refTrack a);

private:
  QVector<refTrack> _tracks;
  QVector<int> _history;
  int _currentIndex = 0;
};

struct UserTrack : Track
{
  Q_OBJECT
public:
  UserTrack(int id = 0, QObject *parent = nullptr);

  QString title() override;
  QString artistsStr() override;
  QString extra() override;
  QString cover() override;
  QMediaContent media() override;

public slots:
  void save();
  bool load();

  void setup(QString media, QString cover, QString title, QString artists, QString extra);

private:
  int id;
  QString _title;
  QString _artists;
  QString _extra;
};
