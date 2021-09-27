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
  Q_PROPERTY(double width READ width WRITE setWidth NOTIFY widthChanged)
  Q_PROPERTY(double height READ height WRITE setHeight NOTIFY heightChanged)
  Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(NextMode nextMode READ nextMode WRITE setNextMode NOTIFY nextModeChanged)
  Q_PROPERTY(LoopMode loopMode READ loopMode WRITE setLoopMode NOTIFY loopModeChanged)
  Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
  Q_PROPERTY(bool darkHeader READ darkHeader WRITE setDarkHeader NOTIFY darkHeaderChanged)
  Q_PROPERTY(bool themeByTime READ themeByTime WRITE setThemeByTime NOTIFY themeByTimeChanged)
  Q_PROPERTY(bool discordPresence READ discordPresence WRITE setDiscordPresence NOTIFY discordPresenceChanged)
  
  
  Q_PROPERTY(QString ym_token READ ym_token WRITE set_ym_token NOTIFY ym_tokenChanged)
  Q_PROPERTY(QString ym_email READ ym_email WRITE set_ym_email NOTIFY ym_emailChanged)
  Q_PROPERTY(QString ym_proxyServer READ ym_proxyServer WRITE set_ym_proxyServer NOTIFY ym_proxyServerChanged)
  Q_PROPERTY(int ym_repeatsIfError READ ym_repeatsIfError WRITE set_ym_repeatsIfError NOTIFY ym_repeatsIfErrorChanged)
  Q_PROPERTY(bool ym_saveAllTracks READ ym_saveAllTracks WRITE set_ym_saveAllTracks NOTIFY ym_saveAllTracksChanged)
  Q_PROPERTY(CoverQuality ym_coverQuality READ ym_coverQuality WRITE set_ym_coverQuality NOTIFY ym_coverQualityChanged)

  static Dir settingsDir();
  static Dir dataDir();

  static Language language();
  static QString colorAccentDark();
  static QString colorAccentLight();
  static bool isClientSideDecorations();
  static double width();
  static double height();
  static double volume();
  static NextMode nextMode();
  static LoopMode loopMode();
  static bool darkTheme();
  static bool darkHeader();
  static bool themeByTime();
  static bool discordPresence();
  
  static Dir user_saveDir();
  static QString user_trackFile(int id);
  
  static QString ym_token();
  static QString ym_email();
  static QString ym_proxyServer();
  static Dir ym_saveDir();
  static QString ym_trackFile(int id);
  static int ym_repeatsIfError();
  static bool ym_saveAllTracks();
  static CoverQuality ym_coverQuality();

public slots:
  void setLanguage(Language v);
  void setColorAccentDark(QString v);
  void setColorAccentLight(QString v);
  void setIsClientSideDecorations(bool v);
  void setWidth(double v);
  void setHeight(double v);
  void setVolume(double v);
  void setNextMode(NextMode v);
  void setLoopMode(LoopMode v);
  void setDarkTheme(bool v);
  void setDarkHeader(bool v);
  void setThemeByTime(bool v);
  void setDiscordPresence(bool v);
  
  
  void set_ym_token(QString v);
  void set_ym_email(QString v);
  void set_ym_proxyServer(QString v);
  void set_ym_repeatsIfError(int v);
  void set_ym_saveAllTracks(bool v);
  void set_ym_coverQuality(CoverQuality v);

  void reloadFromJson();
  void saveToJson();

signals:
  void languageChanged(Language language);
  void colorAccentDarkChanged(QString colorAccentDark);
  void colorAccentLightChanged(QString colorAccentLight);
  void isClientSideDecorationsChanged(bool isClientSideDecorations);
  void widthChanged(double width);
  void heightChanged(double height);
  void volumeChanged(double volume);
  void nextModeChanged(NextMode nextMode);
  void loopModeChanged(LoopMode loopMode);
  void darkThemeChanged(bool darkTheme);
  void darkHeaderChanged(bool darkHeader);
  void themeByTimeChanged(bool themeByTime);
  void discordPresenceChanged(bool discordPresence);
  
  
  void ym_tokenChanged(QString ym_token);
  void ym_emailChanged(QString ym_email);
  void ym_proxyServerChanged(QString ym_proxyServer);
  void ym_repeatsIfErrorChanged(int ym_repeatsIfError);
  void ym_saveAllTracksChanged(bool ym_saveAllTracks);
  void ym_coverQualityChanged(CoverQuality ym_coverQuality);

private:
  inline static Language _language = EnglishLanguage;
  inline static QString _colorAccentDark = "#FCE165";
  inline static QString _colorAccentLight = "#FFA800";
  inline static bool _isClientSideDecorations = true;
  inline static double _width = 1280;
  inline static double _height = 720;
  inline static double _volume = 0.5;
  inline static NextMode _nextMode = NextSequence;
  inline static LoopMode _loopMode = LoopNone;
  inline static bool _darkTheme = true;
  inline static bool _darkHeader = true;
  inline static bool _themeByTime = true;
  inline static bool _discordPresence = false;
  
  
  inline static QString _ym_token = "";
  inline static QString _ym_email = "";
  inline static QString _ym_proxyServer = "";
  inline static int _ym_repeatsIfError = 1;
  inline static bool _ym_saveAllTracks = false;
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
