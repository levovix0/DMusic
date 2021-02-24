#include "yapi.hpp"
#include "file.hpp"
#include<QDebug>
#include<QJsonObject>
#include<QJsonDocument>
#include<filesystem>
#include <thread>

using namespace py;
namespace fs = std::filesystem;

QTextStream& qStdOut()
{
    static QTextStream ts(stdout);
    return ts;
}

Yapi::Yapi(QObject *parent) : QObject(parent)
{
	Py_Initialize();
  ym = module("yandex_music");
  ym_request = ym.get("utils").get("request");
}

Yapi::~Yapi()
{
	Py_FinalizeEx();
}

bool Yapi::isLoggined()
{
  return loggined;
}

QString Yapi::token(QString login, QString password)
{
  return ym.call("generate_token_by_username_and_password", {login, password}).to<QString>();
}

void Yapi::login(QString token)
{
  std::thread([this, token](){
    loggined = false;
    try {
      me = ym.call("Client", token);
      loggined = true;
      emit loggedIn(true);
    } catch (py_error e) {
      emit loggedIn(false);
    }
  }).detach();
}

void Yapi::login(QString token, QString proxy)
{
  std::thread([this, token, proxy](){
    loggined = false;
    try {
      std::map<std::string, object> kwargs;
      kwargs["proxy_url"] = proxy;
      object req = ym_request.call("Request", std::initializer_list<object>{}, kwargs);
      kwargs.clear();
      kwargs["request"] = req;
      me = ym.call("Client", token, kwargs);
      loggined = true;
      emit loggedIn(true);
    } catch (py_error e) {
      emit loggedIn(false);
    }
  }).detach();
}

void Yapi::download(int id, QString outDir)
{
  if (!loggined) return;
  std::thread([this, id, outDir](){
    try {
      if (track.raw == Py_None)
        track = me.call("tracks", std::vector<object>{id})[0];
      fs::path out(outDir.toUtf8().data());
      if (!exists(out)) create_directory(out);
      track.call("download", outDir + QString::number(id) + ".mp3");
      emit downloaded(id, true);
    } catch (py_error e) {
      emit downloaded(id, false);
    }
  }).detach();
}

void Yapi::downloadInfo(int id, QString outDir)
{
  if (!loggined) return;
  std::thread([this, id, outDir](){
    try {
      if (track.raw == Py_None)
        track = me.call("tracks", std::vector<object>{id})[0];

      QJsonObject info;
      info["id"] = id;
      info["title"] = track.get("title").to<QString>();
      info["duration"] = track.get("duration_ms").to<int>();
      info["cover"] = outDir + QString::number(id) + ".png";

      auto json = QJsonDocument(info).toJson(QJsonDocument::Compact);
      File(outDir + QString(id) + ".json", fmWrite) << json.data();
      track.call("download_cover", outDir + QString::number(id) + ".png");

      emit downloadedInfo(id, true);
    } catch (py_error e) {
      emit downloadedInfo(id, false);
    }
  }).detach();
}
