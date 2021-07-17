// This file was generated, don't edit it
#pragma once
#include <QString>
#include <QObject>
#include <QQmlEngine>
#include <QJSEngine>
#include "Dir.hpp"

class Config: public QObject
{
  Q_OBJECT
public:
  Config(QObject* parent = nullptr);
  ~Config();

  static Config* instance;
  static Config* qmlInstance(QQmlEngine*, QJSEngine*);

  enum Language {
    EnglishLanguage,
    RussianLanguage
  };
  Q_ENUM(Language)
  
  enum NextMode {
    NextSequence,
    NextShuffle
  };
  Q_ENUM(NextMode)
  
  enum LoopMode {
    LoopNone,
    LoopTrack,
    LoopPlaylist
  };
  Q_ENUM(LoopMode)
  
  enum CoverQuality {
    MaximumCoverQuality,
    VeryHighCoverQuality,
    HighCoverQuality,
    MediumCoverQuality,
    LowCoverQuality,
    VeryLowCoverQuality,
    MinimumCoverQuality
  };
  Q_ENUM(CoverQuality)

  Q_PROPERTY(Language language READ language WRITE setLanguage NOTIFY languageChanged)
  Q_PROPERTY(QString colorAccentDark READ colorAccentDark WRITE setColorAccentDark NOTIFY colorAccentDarkChanged)
  Q_PROPERTY(QString colorAccentLight READ colorAccentLight WRITE setColorAccentLight NOTIFY colorAccentLightChanged)
  Q_PROPERTY(bool isClientSideDecorations READ isClientSideDecorations WRITE setIsClientSideDecorations NOTIFY isClientSideDecorationsChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)
  Q_PROPERTY(LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
  Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
  Q_PROPERTY(bool darkHeader READ darkHeader WRITE setDarkHeader NOTIFY darkHeaderChanged)
  
  
  Q_PROPERTY(QString ym_token READ ym_token WRITE set_ym_token NOTIFY ym_tokenChanged)
  Q_PROPERTY(QString ym_email READ ym_email WRITE set_ym_email NOTIFY ym_emailChanged)
  Q_PROPERTY(QString ym_proxyServer READ ym_proxyServer WRITE set_ym_proxyServer NOTIFY ym_proxyServerChanged)
  Q_PROPERTY(int ym_repeatsIfError READ ym_repeatsIfError WRITE set_ym_repeatsIfError NOTIFY ym_repeatsIfErrorChanged)
  Q_PROPERTY(bool ym_downloadMedia READ ym_downloadMedia WRITE set_ym_downloadMedia NOTIFY ym_downloadMediaChanged)
  Q_PROPERTY(bool ym_saveCover READ ym_saveCover WRITE set_ym_saveCover NOTIFY ym_saveCoverChanged)
  Q_PROPERTY(bool ym_saveInfo READ ym_saveInfo WRITE set_ym_saveInfo NOTIFY ym_saveInfoChanged)
  Q_PROPERTY(CoverQuality ym_coverQuality READ ym_coverQuality WRITE set_ym_coverQuality NOTIFY ym_coverQualityChanged)

  static Dir settingsDir();
  static Dir dataDir();

  static Language language();
  static QString colorAccentDark();
  static QString colorAccentLight();
  static bool isClientSideDecorations();
  static double volume();
  static NextMode nextMode();
  static LoopMode loopMode();
  static bool darkTheme();
  static bool darkHeader();
  
  static Dir user_saveDir();
  
  static QString ym_token();
  static QString ym_email();
  static QString ym_proxyServer();
  static Dir ym_saveDir();
  static File ym_media(int id);
  static File ym_cover(int id);
  static File ym_metadata(int id);
  static File ym_artistCover(int id);
  static File ym_artistMetadata(int id);
  static int ym_repeatsIfError();
  static bool ym_downloadMedia();
  static bool ym_saveCover();
  static bool ym_saveInfo();
  static CoverQuality ym_coverQuality();

public slots:
  void setLanguage(Language v);
  void setColorAccentDark(QString v);
  void setColorAccentLight(QString v);
  void setIsClientSideDecorations(bool v);
  void setVolume(double v);
  void setNextMode(NextMode v);
  void setLoopMode(LoopMode v);
  void setDarkTheme(bool v);
  void setDarkHeader(bool v);
  
  
  void set_ym_token(QString v);
  void set_ym_email(QString v);
  void set_ym_proxyServer(QString v);
  void set_ym_repeatsIfError(int v);
  void set_ym_downloadMedia(bool v);
  void set_ym_saveCover(bool v);
  void set_ym_saveInfo(bool v);
  void set_ym_coverQuality(CoverQuality v);

  void reloadFromJson();
  void saveToJson();

signals:
  void languageChanged(Language language);
  void colorAccentDarkChanged(QString colorAccentDark);
  void colorAccentLightChanged(QString colorAccentLight);
  void isClientSideDecorationsChanged(bool isClientSideDecorations);
  void volumeChanged(double volume);
  void nextModeChanged(NextMode nextMode);
  void loopModeChanged(LoopMode loopMode);
  void darkThemeChanged(bool darkTheme);
  void darkHeaderChanged(bool darkHeader);
  
  
  void ym_tokenChanged(QString ym_token);
  void ym_emailChanged(QString ym_email);
  void ym_proxyServerChanged(QString ym_proxyServer);
  void ym_repeatsIfErrorChanged(int ym_repeatsIfError);
  void ym_downloadMediaChanged(bool ym_downloadMedia);
  void ym_saveCoverChanged(bool ym_saveCover);
  void ym_saveInfoChanged(bool ym_saveInfo);
  void ym_coverQualityChanged(CoverQuality ym_coverQuality);

private:
  inline static Language _language = EnglishLanguage;
  inline static QString _colorAccentDark = "#FCE165";
  inline static QString _colorAccentLight = "#FFA800";
  inline static bool _isClientSideDecorations = true;
  inline static double _volume = 0.5;
  inline static NextMode _nextMode = NextSequence;
  inline static LoopMode _loopMode = LoopNone;
  inline static bool _darkTheme = true;
  inline static bool _darkHeader = true;
  
  
  inline static QString _ym_token = "";
  inline static QString _ym_email = "";
  inline static QString _ym_proxyServer = "";
  inline static int _ym_repeatsIfError = 1;
  inline static bool _ym_downloadMedia = true;
  inline static bool _ym_saveCover = true;
  inline static bool _ym_saveInfo = true;
  inline static CoverQuality _ym_coverQuality = MaximumCoverQuality;
};

inline QString toString(Config::Language v) {
  if (v == Config::Language::EnglishLanguage) return "";
  else if (v == Config::Language::RussianLanguage) return ":translations/russian";
  return "";
}

inline QString toString(Config::NextMode v) {
  if (v == Config::NextMode::NextSequence) return "NextSequence";
  else if (v == Config::NextMode::NextShuffle) return "NextShuffle";
  return "";
}

inline QString toString(Config::LoopMode v) {
  if (v == Config::LoopMode::LoopNone) return "LoopNone";
  else if (v == Config::LoopMode::LoopTrack) return "LoopTrack";
  else if (v == Config::LoopMode::LoopPlaylist) return "LoopPlaylist";
  return "";
}

inline QString toString(Config::CoverQuality v) {
  if (v == Config::CoverQuality::MaximumCoverQuality) return "1000x1000";
  else if (v == Config::CoverQuality::VeryHighCoverQuality) return "700x700";
  else if (v == Config::CoverQuality::HighCoverQuality) return "600x600";
  else if (v == Config::CoverQuality::MediumCoverQuality) return "400x400";
  else if (v == Config::CoverQuality::LowCoverQuality) return "200x200";
  else if (v == Config::CoverQuality::VeryLowCoverQuality) return "100x100";
  else if (v == Config::CoverQuality::MinimumCoverQuality) return "50x50";
  return "";
}
