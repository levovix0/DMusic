#pragma once
#include <QObject>
#include <QMediaContent>
#include <functional>
#include <settings.hpp>
#include <Track.hpp>
#include <Radio.hpp>
#include <types.hpp>

class Playlist : public QObject
{
  Q_OBJECT
public:
  virtual ~Playlist();
  Playlist(QObject* parent = nullptr);

  refTrack operator[](int index);
  virtual refTrack* begin();
  virtual refTrack* end();

  virtual refTrack get(int index);

  virtual int size();
};

refRadio radio(refPlaylist self, int index = -1, Settings::NextMode nextMode = Settings::NextSequence);

class DPlaylist : public Playlist
{
  Q_OBJECT
public:
  ~DPlaylist();
  DPlaylist(QObject* parent = nullptr);

  refTrack get(int index) override;
  refTrack* begin() override;
  refTrack* end() override;

  int size() override;

public slots:
  void add(refTrack a);

private:
  QVector<refTrack> _tracks;
};

class PlaylistRadio : public Radio
{
public:
  PlaylistRadio(refPlaylist playlist, int index, Settings::NextMode nextMode);
  void setNextMode(Settings::NextMode nextMode) override;
  refTrack current() override;
  refTrack next() override;
  refTrack prev() override;

private:
  int gen();
  void fit();

  refPlaylist _playlist;
  QVector<int> _history{};
  int _index;
  Settings::NextMode _nextMode;
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
