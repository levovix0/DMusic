#include "settings.hpp"
#include <QFile>
#include <QDir>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

Settings::Settings()
{
  connect(this, SIGNAL(reload()), this, SLOT(saveToJson()));
  if (!settingsDir().qfile("settings.json").exists()) saveToJson();  // generate default config
  reloadFromJson();
}

Settings::~Settings()
{
  saveToJson();
}

Dir Settings::settingsDir()
{
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".config"/"DMusic").exists())
    Dir::home().mkpath(".config/DMusic");
  return Dir::home()/".config"/"DMusic";
#else
  return Dir::current();
#endif
}

Dir Settings::dataDir()
{
#ifdef Q_OS_LINUX
  if (!(Dir::home()/".local"/"share"/"DMusic").exists())
    Dir::home().mkpath(".local/share/DMusic");
  return Dir::home()/".local"/"share"/"DMusic";
#else
  return Dir::current();
#endif
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

Dir Settings::ym_saveDir()
{
  if (!(dataDir()/"yandex").exists())
    Dir().mkpath((dataDir()/"yandex").path());
  return dataDir()/"yandex";
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

File Settings::ym_media(int id)
{
  return ym_saveDir().file(QString::number(id) + ".mp3");
}

File Settings::ym_cover(int id)
{
  return ym_saveDir().file(QString::number(id) + ".png");
}

File Settings::ym_metadata(int id)
{
  return ym_saveDir().file(QString::number(id) + ".json");
}

File Settings::ym_artistCover(int id)
{
  return ym_saveDir().file("artist-" + QString::number(id) + ".png");
}

File Settings::ym_artistMetadata(int id)
{
  return ym_saveDir().file("artist-" + QString::number(id) + ".json");
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
  if (!settingsDir().qfile("settings.json").exists()) return;
  QJsonObject doc = settingsDir().file("settings.json").allJson().object();

  _isClientSideDecorations = doc["isClientSideDecorations"].toBool(true);

  setVolume(doc["volume"].toDouble(0.5));
  setNextMode((NextMode)doc["nextMode"].toInt(NextSequence));
  setLoopMode((LoopMode)doc["loopMode"].toInt(LoopNone));

  QJsonObject ym = doc["yandexMusic"].toObject();
  _ym_token = ym["token"].toString("");
  _ym_proxyServer = ym["proxyServer"].toString("");

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

  ym["repeatsIfError"] = _ym_repeatsIfError;
  ym["downloadMedia"] = _ym_downloadMedia;
  ym["saveCover"] = _ym_saveCover;
  ym["saveInfo"] = _ym_saveInfo;
  doc["yandexMusic"] = ym;

  settingsDir().file("settings.json").writeAll(doc, QJsonDocument::Indented);
}
