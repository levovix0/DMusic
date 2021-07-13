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

bool Config::isClientSideDecorations() {
  return _isClientSideDecorations;
}

void Config::setIsClientSideDecorations(bool v) {
  if (_isClientSideDecorations == v) return;
  _isClientSideDecorations = v;
  emit isClientSideDecorationsChanged(_isClientSideDecorations);
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

Dir Config::user_saveDir() {
  auto dir = dataDir()/"user";
  if (!dir.exists()) dir.create();
  return dir;
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

File Config::ym_media(int id) {
  return ym_saveDir().file(QString::number(id) + ".mp3");
}

File Config::ym_cover(int id) {
  return ym_saveDir().file(QString::number(id) + ".png");
}

File Config::ym_metadata(int id) {
  return ym_saveDir().file(QString::number(id) + ".json");
}

File Config::ym_artistCover(int id) {
  return ym_saveDir().file("artist-" + QString::number(id) + ".png");
}

File Config::ym_artistMetadata(int id) {
  return ym_saveDir().file("artist-" + QString::number(id) + ".json");
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

bool Config::ym_downloadMedia() {
  return _ym_downloadMedia;
}

void Config::set_ym_downloadMedia(bool v) {
  if (_ym_downloadMedia == v) return;
  _ym_downloadMedia = v;
  emit ym_downloadMediaChanged(_ym_downloadMedia);
  saveToJson();
}

bool Config::ym_saveCover() {
  return _ym_saveCover;
}

void Config::set_ym_saveCover(bool v) {
  if (_ym_saveCover == v) return;
  _ym_saveCover = v;
  emit ym_saveCoverChanged(_ym_saveCover);
  saveToJson();
}

bool Config::ym_saveInfo() {
  return _ym_saveInfo;
}

void Config::set_ym_saveInfo(bool v) {
  if (_ym_saveInfo == v) return;
  _ym_saveInfo = v;
  emit ym_saveInfoChanged(_ym_saveInfo);
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

  _isClientSideDecorations = doc["isClientSideDecorations"].toBool(true);
  emit isClientSideDecorationsChanged(_isClientSideDecorations);
  _volume = doc["volume"].toDouble(0.5);
  emit volumeChanged(_volume);
  _nextMode = (NextMode)doc["nextMode"].toInt(NextSequence);
  emit nextModeChanged(_nextMode);
  _loopMode = (LoopMode)doc["loopMode"].toInt(LoopNone);
  emit loopModeChanged(_loopMode);
  
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
    _ym_downloadMedia = ym_["downloadMedia"].toBool(true);
    emit ym_downloadMediaChanged(_ym_downloadMedia);
    _ym_saveCover = ym_["saveCover"].toBool(true);
    emit ym_saveCoverChanged(_ym_saveCover);
    _ym_saveInfo = ym_["saveInfo"].toBool(true);
    emit ym_saveInfoChanged(_ym_saveInfo);
    _ym_coverQuality = (CoverQuality)ym_["coverQuality"].toInt(MaximumCoverQuality);
    emit ym_coverQualityChanged(_ym_coverQuality);
  }
}

void Config::saveToJson() {
  QJsonObject doc;

  doc["isClientSideDecorations"] = _isClientSideDecorations;
  doc["volume"] = _volume;
  doc["nextMode"] = _nextMode;
  doc["loopMode"] = _loopMode;
  
  QJsonObject user_;
  doc["User"] = user_;
  
  QJsonObject ym_;
  ym_["token"] = _ym_token;
  ym_["email"] = _ym_email;
  ym_["proxyServer"] = _ym_proxyServer;
  ym_["repeatsIfError"] = _ym_repeatsIfError;
  ym_["downloadMedia"] = _ym_downloadMedia;
  ym_["saveCover"] = _ym_saveCover;
  ym_["saveInfo"] = _ym_saveInfo;
  ym_["coverQuality"] = _ym_coverQuality;
  doc["Yandex.Music"] = ym_;

  settingsDir().file("config.json").writeAll(doc, QJsonDocument::Indented);
}
