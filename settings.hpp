#pragma once
#include <QString>
#include <QObject>
#include "file.hpp"

class Settings : public QObject
{
  Q_OBJECT
public:
  Settings();
  ~Settings();

  enum NextMode {
    NextSequence, NextShuffle, NextRandomAccess
  };
  Q_ENUM(NextMode)

  enum LoopMode {
    LoopNone, LoopTrack, LoopPlaylist
  };
  Q_ENUM(LoopMode)

  Q_PROPERTY(bool isClientSideDecorations READ isClientSideDecorations WRITE set_isClientSideDecorations NOTIFY reload)

  Q_PROPERTY(QString ym_token READ ym_token WRITE set_ym_token NOTIFY reload)
  Q_PROPERTY(QString ym_proxyServer READ ym_proxyServer WRITE set_ym_proxyServer NOTIFY reload)
  Q_PROPERTY(QString ym_savePath READ ym_savePath WRITE set_ym_savePath NOTIFY reload)
  Q_PROPERTY(int ym_repeatsIfError READ ym_repeatsIfError WRITE set_ym_repeatsIfError NOTIFY reload)
  Q_PROPERTY(bool ym_downloadMedia READ ym_downloadMedia WRITE set_ym_downloadMedia NOTIFY reload)

  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)
  Q_PROPERTY(LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)

  static bool isClientSideDecorations();

  static double volume();
  static NextMode nextMode();
  static LoopMode loopMode();

  static QString ym_token();
  static QString ym_proxyServer();

  static QString ym_savePath();
  static int ym_repeatsIfError();
  static bool ym_downloadMedia();

  static QString ym_mediaPath(int id);
  static QString ym_coverPath(int id);
  static QString ym_metadataPath(int id);
  static QString ym_artistCoverPath(int id);
  static QString ym_artistMetadataPath(int id);

  static QString ym_coverQuality() { return "1000x1000"; };

public slots:
  void set_isClientSideDecorations(bool v);

  void setVolume(double v);
  void setNextMode(NextMode v);
  void setLoopMode(LoopMode v);

  void set_ym_token(QString v);
  void set_ym_proxyServer(QString v);
  void set_ym_savePath(QString v);
  void set_ym_repeatsIfError(int v);
  void set_ym_downloadMedia(bool v);

  void reloadFromJson();
  void saveToJson();

signals:
  void reload();

  void volumeChanged(double volume);
  void nextModeChanged(NextMode nextMode);
  void loopModeChanged(LoopMode loopMode);

private:
  inline static bool _isClientSideDecorations = true;

  inline static double _volume = 0.5;
  inline static NextMode _nextMode = NextSequence;
  inline static LoopMode _loopMode = LoopNone;

  inline static QString _ym_token = "";
  inline static QString _ym_proxyServer = "";
  inline static QString _ym_savePath = "yandex/";
  inline static int _ym_repeatsIfError = 1;
  inline static bool _ym_downloadMedia = true;
  inline static bool _ym_saveCover = true; //TODO
  inline static bool _ym_saveInfo = true; //TODO
};
