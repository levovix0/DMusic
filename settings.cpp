#include "settings.hpp"
#include <QFile>
#include <QDir>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

Settings::Settings()
{
  connect(this, SIGNAL(reload()), this, SLOT(saveToJson()));
  reloadFromJson();
}

Settings::~Settings()
{
  saveToJson();
}


bool Settings::isClientSideDecorations()
{
  return _isClientSideDecorations;
}

double Settings::volume()
{
  return _volume;
}

Settings::NextMode Settings::nextMode()
{
  return _nextMode;
}

Settings::LoopMode Settings::loopMode()
{
  return _loopMode;
}

QString Settings::ym_token()
{
  return _ym_token;
}

QString Settings::ym_proxyServer()
{
  return _ym_proxyServer;
}

QString Settings::ym_savePath()
{
  if (!QDir(_ym_savePath).exists())
    QDir::current().mkpath(_ym_savePath);
  return QDir(_ym_savePath).canonicalPath();
}

int Settings::ym_repeatsIfError()
{
  return _ym_repeatsIfError;
}

bool Settings::ym_downloadMedia()
{
  return _ym_downloadMedia;
}

bool Settings::ym_saveCover()
{
  return _ym_saveCover;
}

bool Settings::ym_saveInfo()
{
  return _ym_saveInfo;
}

QString Settings::ym_mediaPath(int id)
{
  return QDir::cleanPath(ym_savePath() + QDir::separator() + (QString::number(id) + ".mp3"));
}

QString Settings::ym_coverPath(int id)
{
  return QDir::cleanPath(ym_savePath() + QDir::separator() + (QString::number(id) + ".png"));
}

QString Settings::ym_metadataPath(int id)
{
  return QDir::cleanPath(ym_savePath() + QDir::separator() + (QString::number(id) + ".json"));
}

QString Settings::ym_artistCoverPath(int id)
{
  return QDir::cleanPath(ym_savePath() + QDir::separator() + ("artist-" + QString::number(id) + ".png"));
}

QString Settings::ym_artistMetadataPath(int id)
{
  return QDir::cleanPath(ym_savePath() + QDir::separator() + ("artist-" + QString::number(id) + ".json"));
}

void Settings::set_isClientSideDecorations(bool v)
{
  _isClientSideDecorations = v;
  emit reload();
}

void Settings::setVolume(double v)
{
  _volume = v;
  emit volumeChanged(v);
}

void Settings::setNextMode(Settings::NextMode v)
{
  _nextMode = v;
  emit nextModeChanged(v);
}

void Settings::setLoopMode(Settings::LoopMode v)
{
  _loopMode = v;
  emit loopModeChanged(v);
}

void Settings::set_ym_token(QString v)
{
  _ym_token = v;
  emit reload();
}

void Settings::set_ym_proxyServer(QString v)
{
  _ym_proxyServer = v;
  emit reload();
}

void Settings::set_ym_savePath(QString v)
{
  _ym_savePath = v.toUtf8().data();
  emit reload();
}

void Settings::set_ym_repeatsIfError(int v)
{
  _ym_repeatsIfError = v;
  emit reload();
}

void Settings::set_ym_downloadMedia(bool v)
{
  _ym_downloadMedia = v;
  emit reload();
}

void Settings::set_ym_saveCover(bool v)
{
  _ym_saveCover = v;
  emit reload();
}

void Settings::set_ym_saveInfo(bool v)
{
  _ym_saveInfo = v;
  emit reload();
}


void Settings::reloadFromJson()
{
  if (!QFileInfo::exists("settings.json")) return;
  QJsonObject doc = File("settings.json").allJson().object();

  _isClientSideDecorations = doc["isClientSideDecorations"].toBool(true);

  setVolume(doc["volume"].toDouble(0.5));
  setNextMode((NextMode)doc["nextMode"].toInt(NextSequence));
  setLoopMode((LoopMode)doc["loopMode"].toInt(LoopNone));

  QJsonObject ym = doc["yandexMusic"].toObject();
  _ym_token = ym["token"].toString("");
  _ym_proxyServer = ym["proxyServer"].toString("");

  _ym_savePath = ym["savePath"].toString("yandex/");
  _ym_repeatsIfError = ym["repeatsIfError"].toInt(1);
  _ym_downloadMedia = ym["downloadMedia"].toBool(true);
  _ym_saveCover = ym["saveCover"].toBool(true);
  _ym_saveInfo = ym["saveInfo"].toBool(true);

  disconnect(SIGNAL(reload()));
  emit reload();
  connect(this, SIGNAL(reload()), this, SLOT(saveToJson()));
}

void Settings::saveToJson()
{
  QJsonObject doc;

  doc["isClientSideDecorations"] = _isClientSideDecorations;

  doc["volume"] = _volume;
  doc["nextMode"] = _nextMode;
  doc["loopMode"] = _loopMode;

  QJsonObject ym;
  ym["token"] = _ym_token;
  ym["proxyServer"] = _ym_proxyServer;

  ym["savePath"] = _ym_savePath;
  ym["repeatsIfError"] = _ym_repeatsIfError;
  ym["downloadMedia"] = _ym_downloadMedia;
  ym["saveCover"] = _ym_saveCover;
  ym["saveInfo"] = _ym_saveInfo;
  doc["yandexMusic"] = ym;

  File("settings.json").writeAll(doc, QJsonDocument::Indented);
}
