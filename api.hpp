#pragma once
#include <QObject>
#include <QMediaContent>
#include <functional>
#include <settings.hpp>

struct Playlist;

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

struct refTrack_
{
  ~refTrack_();
  refTrack_(Track* a);
  refTrack_(Track* a, Playlist* playlist);
  refTrack_(refTrack_ const& copy);
  refTrack_(refTrack_ const& copy, Playlist* playlist);
  refTrack_ operator=(refTrack_ const& copy);
  operator Track*();

  bool operator==(refTrack_ const& b) const;
  bool operator==(Track* b) const;

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
  using Generator = std::pair<std::function<refTrack_()>, std::function<refTrack_()>>;

  virtual ~Playlist();
  Playlist(QObject* parent = nullptr);

  static Playlist none;

  refTrack_ operator[](int index);

  virtual QVector<Settings::NextMode> modesSupported() { return {}; }
  virtual refTrack_ get(int index);
  virtual Generator sequenceGenerator(int index = -1);
  virtual Generator shuffleGenerator(int index = -1);
  virtual Generator randomAccessGenerator(int index = -1);
  virtual Generator generator(int index = -1, Settings::NextMode prefered = Settings::NextSequence); // auto-detect

  virtual int size(); // -1 means infinity or not determined

private:
};

struct DPlaylist : Playlist
{
  Q_OBJECT
public:
  ~DPlaylist();
  DPlaylist(QObject* parent = nullptr);

  QVector<Settings::NextMode> modesSupported() override { return { Settings::NextSequence, Settings::NextShuffle, Settings::NextRandomAccess }; }
  refTrack_ get(int index) override;
  Generator sequenceGenerator(int index = -1) override;
  Generator shuffleGenerator(int index = -1) override;
  Generator randomAccessGenerator(int index = -1) override;

  int size() override;

public slots:

  void add(Track* a);
  void remove(Track* a);

private:
  QVector<refTrack_> _tracks;
  QVector<refTrack_> _history;
  int _currentIndex = 0;
};

struct Client : QObject
{
  Q_OBJECT
public:

private:
};

// TODO: client, освобождающий мусор, когда все говорят ему, что больше не используют трек
