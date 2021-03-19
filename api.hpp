#pragma once
#include <QObject>
#include <QMediaContent>
#include <functional>

struct Playlist;

enum class NextMode {
  Sequence, Shuffle, RandomAccess
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

struct refTrack
{
  ~refTrack();
  refTrack(Track* a);
  refTrack(Track* a, Playlist* playlist);
  refTrack(refTrack const& copy);
  refTrack(refTrack const& copy, Playlist* playlist);
  refTrack operator=(refTrack const& copy);
  operator Track*();

  QString title();
  QString author();
  QString extra();
  QString cover();
  QMediaContent media();
  qint64 duration();

  bool isNone();

  Track* ref();
  Playlist* attachedPlaylist();

private:
  Track* _ref;
  Playlist* _attachedPlaylist = nullptr;
};

struct Playlist : QObject
{
  Q_OBJECT
public:
  Q_ENUM(NextMode)
  using Generator = std::pair<std::function<refTrack()>, std::function<refTrack()>>;

  virtual ~Playlist();
  Playlist(QObject* parent = nullptr);

  static Playlist none;

  refTrack operator[](int index);

  virtual QVector<NextMode> modesSupported() { return {}; }
  virtual refTrack get(int index);
  virtual Generator sequenceGenerator(int index = -1);
  virtual Generator shuffleGenerator(int index = -1);
  virtual Generator randomAccessGenerator(int index = -1);
  virtual Generator generator(int index = -1, NextMode prefered = NextMode::Sequence); // auto-detect

  virtual int size(); // -1 means infinity or not determined

private:
};

struct DPlaylist : Playlist
{
  Q_OBJECT
public:
  ~DPlaylist();
  DPlaylist(QObject* parent = nullptr);

//  QVector<NextMode> modesSupported() override { return { NextMode::Sequence, NextMode::Shuffle, NextMode::RandomAccess }; }
  QVector<NextMode> modesSupported() override { return { NextMode::Sequence, NextMode::RandomAccess }; }
  refTrack get(int index) override;
  Generator sequenceGenerator(int index = -1) override;
  Generator shuffleGenerator(int index = -1) override;
  Generator randomAccessGenerator(int index = -1) override;

  int size() override;

public slots:

  void add(Track* a);
  void remove(Track* a);

private:
  QVector<refTrack> _tracks;
  QVector<refTrack> _history;
  int _lastIndex = 0;
};

struct Client : QObject
{
  Q_OBJECT
public:

private:
};

// TODO: client, освобождающий мусор, когда все говорят ему, что больше не используют трек
