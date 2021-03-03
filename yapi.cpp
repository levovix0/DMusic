#include "yapi.hpp"
#include "file.hpp"
#include "settings.hpp"
#include "utils.hpp"
#include <QDebug>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QGuiApplication>
#include <thread>
#include <functional>

using namespace py;
namespace fs = std::filesystem;

QTextStream& qStdOut()
{
    static QTextStream ts(stdout);
    return ts;
}

object repeat_if_error(std::function<object()> f, int n = 10, std::string s = "NetworkError") {
  if (s == "") {
    while (true) {
      try {
        return f();
      }  catch (py_error& e) {
        --n;
        if (n <= 0) throw std::move(e);
      }
    }
  } else {
    while (true) {
      try {
        return f();
      }  catch (py_error& e) {
        if (e.type != s) throw std::move(e);
        --n;
        if (n <= 0) throw std::move(e);
      }
    }
  }
  return nullptr;
}

void repeat_if_error(std::function<void()> f, std::function<void(bool success)> r, int n = 10, std::string s = "NetworkError") {
  int tries = n;
  if (s == "") {
    while (true) {
      try {
        f();
        r(true);
        return;
      }  catch (py_error& e) {
        --tries;
        if (tries <= 0) {
          r(false);
          return;
        }
      }
    }
  } else {
    while (true) {
      try {
        f();
        r(true);
        return;
      }  catch (py_error& e) {
        if (e.type != s) {
          r(false);
          return;
        }
        --tries;
        if (tries <= 0) {
          r(false);
          return;
        }
      }
    }
  }
}

void do_async(std::function<void()> f) {
  std::thread(f).detach();
}

void repeat_if_error_async(std::function<void()> f, std::function<void(bool success)> r, int n = 10, std::string s = "NetworkError") {
  do_async([=]() {
    int tries = n;
    if (s == "") {
      while (true) {
        try {
          f();
          r(true);
          return;
        }  catch (py_error& e) {
          --tries;
          if (tries <= 0) {
            r(false);
            return;
          }
        }
      }
    } else {
      while (true) {
        try {
          f();
          r(true);
          return;
        }  catch (py_error& e) {
          if (e.type != s) {
            r(false);
            return;
          }
          --tries;
          if (tries <= 0) {
            r(false);
            return;
          }
        }
      }
    }
  });
}


YClient::YClient(QObject *parent) : QObject(parent), ym("yandex_music"), ym_request(ym/"utils"/"request")
{

}

YClient::YClient(const YClient& copy) : QObject(nullptr), ym(copy.ym), ym_request(copy.ym_request), me(copy.me), loggined((bool)copy.loggined)
{

}

YClient& YClient::operator=(const YClient& copy)
{
  ym = copy.ym;
  ym_request = copy.ym_request;
  me = copy.me;
  loggined = (bool)copy.loggined;
  return *this;
}

YClient::~YClient()
{
}

bool YClient::isLoggined()
{
  return loggined;
}

QString YClient::token(QString login, QString password)
{
  return ym.call("generate_token_by_username_and_password", {login, password}).to<QString>();
}

bool YClient::login(QString token)
{
  loggined = false;
  repeat_if_error([this, token]() {
    me = ym.call("Client", token);
  }, [this](bool success) {
    loggined = success;
  }, ym_repeats_if_error());
  return loggined;
}

void YClient::login(QString token, const QJSValue& callback)
{
  do_async<bool>(this, callback, &YClient::login, token);
}

bool YClient::loginViaProxy(QString token, QString proxy)
{
  loggined = false;
  repeat_if_error([this, token, proxy]() {
    std::map<std::string, object> kwargs;
    kwargs["proxy_url"] = proxy;
    object req = ym_request.call("Request", std::initializer_list<object>{}, kwargs);
    kwargs.clear();
    kwargs["request"] = req;
    me = ym.call("Client", token, kwargs);
  }, [this](bool success) {
    loggined = success;
  }, ym_repeats_if_error());
  return loggined;
}

void YClient::loginViaProxy(QString token, QString proxy, const QJSValue& callback)
{
  do_async<bool>(this, callback, &YClient::loginViaProxy, token, proxy);
}

std::pair<bool, QList<YTrack*>> YClient::fetchTracks(int id)
{
  QList<YTrack*> tracks;
  bool successed;
  repeat_if_error([this, id, &tracks]() {
    tracks = me.call("tracks", std::vector<object>{id}).to<QList<YTrack*>>(); // утечка памяти?
  }, [&successed](bool success) {
    successed = success;
  }, ym_repeats_if_error());
  move_to_thread(tracks, QGuiApplication::instance()->thread());
  return {successed, tracks};
}

void YClient::fetchTracks(int id, const QJSValue& callback)
{
  do_async<bool, QList<YTrack*>>(this, callback, &YClient::fetchTracks, id);
}


YTrack::YTrack(object track, QObject* parent) : QObject(parent)
{
  this->impl = track;
  this->_id = track.get("id").to<int>();
}

YTrack::YTrack()
{

}

YTrack::YTrack(const YTrack& copy) : QObject(nullptr), impl(copy.impl), _id(copy._id)
{

}

YTrack& YTrack::operator=(const YTrack& copy)
{
  impl = copy.impl;
  _id = copy._id;
  return *this;
}

int YTrack::id()
{
  return _id;
//  return impl.get("id").to<int>();
}

QString YTrack::title()
{
  return impl.get("title").to<QString>();
}

int YTrack::duration()
{
  return impl.get("duration_ms").to<int>();
}

bool YTrack::available()
{
  return impl.get("available").to<bool>();
}

QVector<YArtist> YTrack::artists()
{
  return impl.get("artists").to<QVector<YArtist>>();
}

QString YTrack::coverPath()
{
  return QString((ym_save_path() / (QString::number(id()) + ".png")).string().c_str());
}

QString YTrack::metadataPath()
{
  return QString((ym_save_path() / (QString::number(id()) + ".json")).string().c_str());
}

QString YTrack::soundPath()
{
  return QString((ym_save_path() / (QString::number(id()) + ".mp3")).string().c_str());
}

QJsonObject YTrack::jsonMetadata()
{
  QJsonObject info;
  info["id"] = id();
  info["title"] = title();
  info["duration"] = duration();
  info["cover"] = coverPath();
  QJsonArray artists;
  for (auto&& artist : this->artists()) {
    artists.append(artist.id());
  }
  info["artists"] = artists;
  return info;
}

QString YTrack::stringMetadata()
{
  auto json = QJsonDocument(jsonMetadata()).toJson(QJsonDocument::Compact);
  return json.data();
}

void YTrack::saveMetadata()
{
  File(metadataPath(), fmWrite) << stringMetadata();
}

bool YTrack::saveCover(int quality)
{
  bool successed;
  QString size = QString::number(quality) + "x" + QString::number(quality);
  repeat_if_error([this, size]() {
    impl.call("download_cover", std::initializer_list<object>{coverPath(), size});
  }, [&successed](bool success) {
    successed = success;
  }, ym_repeats_if_error());
  return successed;
}

void YTrack::saveCover(int quality, const QJSValue& callback)
{
  do_async<bool>(this, callback, &YTrack::saveCover, quality);
}

bool YTrack::download()
{
  bool successed;
  repeat_if_error([this]() {
    impl.call("download", soundPath());
  }, [&successed](bool success) {
    successed = success;
  }, ym_repeats_if_error());
  return successed;
}

void YTrack::download(const QJSValue& callback)
{
  do_async<bool>(this, callback, &YTrack::download);
}


YArtist::YArtist(object impl, QObject* parent) : QObject(parent)
{
  this->impl = impl;
  _id = impl.get("id").to<int>();
}

YArtist::YArtist()
{

}

YArtist::YArtist(const YArtist& copy) : QObject(nullptr), impl(copy.impl), _id(copy._id)
{

}

YArtist& YArtist::operator=(const YArtist& copy)
{
  impl = copy.impl;
  _id = copy._id;
  return *this;
}

int YArtist::id()
{
  return _id;
}

QString YArtist::name()
{
  return impl.get("name").to<QString>();
}

QString YArtist::coverPath()
{
  return QString((ym_save_path() / ("artist-" + QString::number(id()) + ".png")).string().c_str());
}

QString YArtist::metadataPath()
{
  return QString((ym_save_path() / ("artist-" + QString::number(id()) + ".json")).string().c_str());
}

QJsonObject YArtist::jsonMetadata()
{
  QJsonObject info;
  info["id"] = id();
  info["name"] = name();
  info["cover"] = coverPath();
  return info;
}

QString YArtist::stringMetadata()
{
  auto json = QJsonDocument(jsonMetadata()).toJson(QJsonDocument::Compact);
  return json.data();
}

void YArtist::saveMetadata()
{
  File(metadataPath(), fmWrite) << stringMetadata();
}

bool YArtist::saveCover(int quality)
{
  bool successed;
  QString size = QString::number(quality) + "x" + QString::number(quality);
  repeat_if_error([this, size]() {
    impl.call("download_og_image", std::initializer_list<object>{coverPath(), size});
  }, [&successed](bool success) {
    successed = success;
  }, ym_repeats_if_error());
  return successed;
}

void YArtist::saveCover(int quality, const QJSValue& callback)
{
  do_async<bool>(this, callback, &YArtist::saveCover, quality);
}
