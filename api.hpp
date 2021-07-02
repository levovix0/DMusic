#pragma once
#include <QObject>
#include <QMediaContent>
#include <functional>
#include "Config.hpp"
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

  virtual void markErrorTrack(int index);

signals:
  void trackRemoved(int index);
};

refRadio radio(refPlaylist self, int index = -1, Config::NextMode nextMode = Config::NextSequence);

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

  void markErrorTrack(int index) override;

public slots:
  void add(refTrack a);
  void remove(int index);

private:
  QVector<refTrack> _tracks;
};

//TODO: DownloadsPlaylist, удаляющий треки с диска, если их не удалось загрузить

class PlaylistRadio : public Radio
{
  Q_OBJECT
public:
  PlaylistRadio(QObject* parent = nullptr);
  PlaylistRadio(refPlaylist playlist, int index, Config::NextMode nextMode, QObject* parent = nullptr);
	void setNextMode(Config::NextMode nextMode) override;
  refTrack current() override;
  refTrack next() override;
  refTrack prev() override;

  refTrack markErrorCurrentTrack() override;

private slots:
  void handleTrackRemoved(int index);

private:
  int gen();
  void fit();

  refPlaylist _playlist;
  QVector<int> _history{};
  int _index;
	Config::NextMode _nextMode;
};

struct UserTrack : Track
{
  Q_OBJECT
public:
  //TODO: сжимать обложку в размерах, если она больше 1000x1000
  UserTrack(int id = 0, QObject *parent = nullptr);

  QString title() override;
  QString artistsStr() override;
  QString extra() override;
  QUrl cover() override;
  QMediaContent media() override;

  static Dir userDir();

public slots:
  void save();
  bool load();

  void setup(QUrl media, QUrl cover, QString title, QString artists, QString extra);

private:
  int id;
  QString _title;
  QString _artists;
  QString _extra;
};
