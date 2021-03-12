#include "settings.hpp"
#include <QFile>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

Settings::Settings()
{
  connect(this, SIGNAL(reload), this, SLOT(saveToJson));
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

QString Settings::ym_token()
{
  return _ym_token;
}

QString Settings::ym_proxyServer()
{
  return _ym_proxyServer;
}

fs::path Settings::ym_savePath_()
{
  if (!exists(_ym_savePath)) {
    create_directory(_ym_savePath);
  }
  return canonical(_ym_savePath);
}

QString Settings::ym_savePath()
{
  return qstr(ym_savePath_());
}

int Settings::ym_repeatsIfError()
{
  return _ym_repeatsIfError;
}

QString Settings::ym_mediaPath(int id)
{
  return (ym_savePath_() / (std::to_string(id) + ".mp3")).string().c_str();
}

QString Settings::ym_coverPath(int id)
{
  return (ym_savePath_() / (std::to_string(id) + ".png")).string().c_str();
}

QString Settings::ym_metadataPath(int id)
{
  return (ym_savePath_() / (std::to_string(id) + ".json")).string().c_str();
}

QString Settings::ym_artistCoverPath(int id)
{
  return (ym_savePath_() / ("artist-" + std::to_string(id) + ".png")).string().c_str();
}

QString Settings::ym_artistMetadataPath(int id)
{
  return (ym_savePath_() / ("artist-" + std::to_string(id) + ".json")).string().c_str();
}


bool Settings::get_isClientSideDecorations()
{
  return isClientSideDecorations();
}

void Settings::set_isClientSideDecorations(bool v)
{
  _isClientSideDecorations = v;
  emit reload();
}

QString Settings::get_ym_token()
{
  return ym_token();
}

void Settings::set_ym_token(QString v)
{
  _ym_token = v;
  emit reload();
}

QString Settings::get_ym_proxyServer()
{
  return ym_proxyServer();
}

void Settings::set_ym_proxyServer(QString v)
{
  _ym_proxyServer = v;
  emit reload();
}

QString Settings::get_ym_savePath()
{
  return ym_savePath();
}

void Settings::set_ym_savePath(QString v)
{
  _ym_savePath = v.toUtf8().data();
  emit reload();
}

int Settings::get_ym_repeatsIfError()
{
  return _ym_repeatsIfError;
}

void Settings::set_ym_repeatsIfError(int v)
{
  _ym_repeatsIfError = v;
  emit reload();
}


void Settings::reloadFromJson()
{
  if (!fs::exists("settings.json")) return;

  QString val;
  QFile file;
  file.setFileName("settings.json");
  file.open(QIODevice::ReadOnly | QIODevice::Text);
  val = file.readAll();
  file.close();
  QJsonObject doc = QJsonDocument::fromJson(val.toUtf8()).object();

  _isClientSideDecorations = doc["isClientSideDecorations"].toBool(true);

  QJsonObject ym = doc["yandexMusic"].toObject();
  _ym_token = ym["token"].toString("");
  _ym_proxyServer = ym["proxyServer"].toString("");

  _ym_savePath = ym["savePath"].toString("yandex/").toUtf8().data();
  _ym_repeatsIfError = ym["repeatsIfError"].toInt(1);

  disconnect(SIGNAL(reload));
  emit reload();
  connect(this, SIGNAL(reload), this, SLOT(saveToJson));
}

void Settings::saveToJson()
{
  QJsonObject doc;

  doc["isClientSideDecorations"] = _isClientSideDecorations;

  QJsonObject ym;
  ym["token"] = _ym_token;
  ym["proxyServer"] = _ym_proxyServer;

  ym["savePath"] = qstr(_ym_savePath);
  ym["repeatsIfError"] = _ym_repeatsIfError;
  doc["yandexMusic"] = ym;

  auto json = QJsonDocument(doc).toJson(QJsonDocument::Indented);
  File("settings.json", fmWrite) << json.data();
}
