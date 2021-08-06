// This file was generated, don't edit it
#include "Config.hpp"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>


Config* Config::instance = new Config();

Config::Config(QObject* parent) : QObject(parent) {
  if (!settingsDir().qfile("config.json").exists())
    saveToJson();  // generate default config
  else
    reloadFromJson();
}

Config::~Config() {}

Config* Config::qmlInstance(QQmlEngine*, QJSEngine*) {
  return instance;
}

Dir Config::settingsDir() {
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".config"/"DMusic").exists())
    Dir::home().mkpath(".config/DMusic");
  return Dir::home()/".config"/"DMusic";
#else
  return Dir::current();
#endif
}

Dir Config::dataDir() {
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".local"/"share"/"DMusic").exists())
    Dir::home().mkpath(".local/share/DMusic");
  return Dir::home()/".local"/"share"/"DMusic";
#else
  return Dir::current();
#endif
}

Config::Language Config::language() {
  return _language;
}

void Config::setLanguage(Config::Language v) {
  if (_language == v) return;
  _language = v;
  emit languageChanged(_language);
  saveToJson();
}

QString Config::colorAccentDark() {
  return _colorAccentDark;
}

void Config::setColorAccentDark(QString v) {
  if (_colorAccentDark == v) return;
  _colorAccentDark = v;
  emit colorAccentDarkChanged(_colorAccentDark);
  saveToJson();
}

QString Config::colorAccentLight() {
  return _colorAccentLight;
}

void Config::setColorAccentLight(QString v) {
  if (_colorAccentLight == v) return;
  _colorAccentLight = v;
  emit colorAccentLightChanged(_colorAccentLight);
  saveToJson();
}

bool Config::isClientSideDecorations() {
  return _isClientSideDecorations;
}

void Config::setIsClientSideDecorations(bool v) {
  if (_isClientSideDecorations == v) return;
  _isClientSideDecorations = v;
  emit isClientSideDecorationsChanged(_isClientSideDecorations);
  saveToJson();
}

double Config::width() {
  return _width;
}

void Config::setWidth(double v) {
  if (_width == v) return;
  _width = v;
  emit widthChanged(_width);
  saveToJson();
}

double Config::height() {
  return _height;
}

void Config::setHeight(double v) {
  if (_height == v) return;
  _height = v;
  emit heightChanged(_height);
  saveToJson();
}

double Config::volume() {
  return _volume;
}

void Config::setVolume(double v) {
  if (_volume == v) return;
  _volume = v;
  emit volumeChanged(_volume);
  saveToJson();
}

Config::NextMode Config::nextMode() {
  return _nextMode;
}

void Config::setNextMode(Config::NextMode v) {
  if (_nextMode == v) return;
  _nextMode = v;
  emit nextModeChanged(_nextMode);
  saveToJson();
}

Config::LoopMode Config::loopMode() {
  return _loopMode;
}

void Config::setLoopMode(Config::LoopMode v) {
  if (_loopMode == v) return;
  _loopMode = v;
  emit loopModeChanged(_loopMode);
  saveToJson();
}

bool Config::darkTheme() {
  return _darkTheme;
}

void Config::setDarkTheme(bool v) {
  if (_darkTheme == v) return;
  _darkTheme = v;
  emit darkThemeChanged(_darkTheme);
  saveToJson();
}

bool Config::darkHeader() {
  return _darkHeader;
}

void Config::setDarkHeader(bool v) {
  if (_darkHeader == v) return;
  _darkHeader = v;
  emit darkHeaderChanged(_darkHeader);
  saveToJson();
}

Dir Config::user_saveDir() {
  auto dir = dataDir()/"user";
  if (!dir.exists()) dir.create();
  return dir;
}

QString Config::user_trackFile(int id) {
  return user_saveDir().sub(QString::number(id) + ".mp3");
}

QString Config::ym_token() {
  return _ym_token;
}

void Config::set_ym_token(QString v) {
  if (_ym_token == v) return;
  _ym_token = v;
  emit ym_tokenChanged(_ym_token);
  saveToJson();
}

QString Config::ym_email() {
  return _ym_email;
}

void Config::set_ym_email(QString v) {
  if (_ym_email == v) return;
  _ym_email = v;
  emit ym_emailChanged(_ym_email);
  saveToJson();
}

QString Config::ym_proxyServer() {
  return _ym_proxyServer;
}

void Config::set_ym_proxyServer(QString v) {
  if (_ym_proxyServer == v) return;
  _ym_proxyServer = v;
  emit ym_proxyServerChanged(_ym_proxyServer);
  saveToJson();
}

Dir Config::ym_saveDir() {
  auto dir = dataDir()/"yandex";
  if (!dir.exists()) dir.create();
  return dir;
}

QString Config::ym_trackFile(int id) {
  return ym_saveDir().sub(QString::number(id) + ".mp3");
}

int Config::ym_repeatsIfError() {
  return _ym_repeatsIfError;
}

void Config::set_ym_repeatsIfError(int v) {
  if (_ym_repeatsIfError == v) return;
  _ym_repeatsIfError = v;
  emit ym_repeatsIfErrorChanged(_ym_repeatsIfError);
  saveToJson();
}

bool Config::ym_saveAllTracks() {
  return _ym_saveAllTracks;
}

void Config::set_ym_saveAllTracks(bool v) {
  if (_ym_saveAllTracks == v) return;
  _ym_saveAllTracks = v;
  emit ym_saveAllTracksChanged(_ym_saveAllTracks);
  saveToJson();
}

Config::CoverQuality Config::ym_coverQuality() {
  return _ym_coverQuality;
}

void Config::set_ym_coverQuality(Config::CoverQuality v) {
  if (_ym_coverQuality == v) return;
  _ym_coverQuality = v;
  emit ym_coverQualityChanged(_ym_coverQuality);
  saveToJson();
}

void Config::reloadFromJson() {
  if (!settingsDir().qfile("config.json").exists()) return;
  QJsonObject doc = settingsDir().file("config.json").allJson().object();
  if (doc.isEmpty()) return;

  _language = (Language)doc["language"].toInt(EnglishLanguage);
  emit languageChanged(_language);
  _colorAccentDark = doc["colorAccentDark"].toString("#FCE165");
  emit colorAccentDarkChanged(_colorAccentDark);
  _colorAccentLight = doc["colorAccentLight"].toString("#FFA800");
  emit colorAccentLightChanged(_colorAccentLight);
  _isClientSideDecorations = doc["isClientSideDecorations"].toBool(true);
  emit isClientSideDecorationsChanged(_isClientSideDecorations);
  _width = doc["width"].toDouble(1280);
  emit widthChanged(_width);
  _height = doc["height"].toDouble(720);
  emit heightChanged(_height);
  _volume = doc["volume"].toDouble(0.5);
  emit volumeChanged(_volume);
  _nextMode = (NextMode)doc["nextMode"].toInt(NextSequence);
  emit nextModeChanged(_nextMode);
  _loopMode = (LoopMode)doc["loopMode"].toInt(LoopNone);
  emit loopModeChanged(_loopMode);
  _darkTheme = doc["darkTheme"].toBool(true);
  emit darkThemeChanged(_darkTheme);
  _darkHeader = doc["darkHeader"].toBool(true);
  emit darkHeaderChanged(_darkHeader);
  
  QJsonObject user_ = doc["User"].toObject();
  if (!user_.isEmpty()) {
    
  }
  
  QJsonObject ym_ = doc["Yandex.Music"].toObject();
  if (!ym_.isEmpty()) {
    _ym_token = ym_["token"].toString("");
    emit ym_tokenChanged(_ym_token);
    _ym_email = ym_["email"].toString("");
    emit ym_emailChanged(_ym_email);
    _ym_proxyServer = ym_["proxyServer"].toString("");
    emit ym_proxyServerChanged(_ym_proxyServer);
    _ym_repeatsIfError = ym_["repeatsIfError"].toInt(1);
    emit ym_repeatsIfErrorChanged(_ym_repeatsIfError);
    _ym_saveAllTracks = ym_["saveAllTracks"].toBool(false);
    emit ym_saveAllTracksChanged(_ym_saveAllTracks);
    _ym_coverQuality = (CoverQuality)ym_["coverQuality"].toInt(MaximumCoverQuality);
    emit ym_coverQualityChanged(_ym_coverQuality);
  }
}

void Config::saveToJson() {
  QJsonObject doc;

  doc["language"] = _language;
  doc["colorAccentDark"] = _colorAccentDark;
  doc["colorAccentLight"] = _colorAccentLight;
  doc["isClientSideDecorations"] = _isClientSideDecorations;
  doc["width"] = _width;
  doc["height"] = _height;
  doc["volume"] = _volume;
  doc["nextMode"] = _nextMode;
  doc["loopMode"] = _loopMode;
  doc["darkTheme"] = _darkTheme;
  doc["darkHeader"] = _darkHeader;
  
  QJsonObject user_;
  doc["User"] = user_;
  
  QJsonObject ym_;
  ym_["token"] = _ym_token;
  ym_["email"] = _ym_email;
  ym_["proxyServer"] = _ym_proxyServer;
  ym_["repeatsIfError"] = _ym_repeatsIfError;
  ym_["saveAllTracks"] = _ym_saveAllTracks;
  ym_["coverQuality"] = _ym_coverQuality;
  doc["Yandex.Music"] = ym_;

  settingsDir().file("config.json").writeAll(doc, QJsonDocument::Indented);
}
