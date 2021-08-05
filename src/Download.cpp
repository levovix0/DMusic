#include "Download.hpp"
#include <thread>

using namespace std::chrono_literals;

Download::Download(QObject* parent) : QObject(parent)
{
  connect(&_networkControl, &QNetworkAccessManager::finished, this, &Download::onFinished);
}

Download::Download(QUrl const& url, QObject* parent) : Download(parent)
{
  start(url);
}

Download::~Download()
{}

void Download::start(const QUrl& url)
{
  _networkControl.get(QNetworkRequest(url));
}

void Download::onFinished(QNetworkReply* reply)
{
  emit finished(reply->readAll());
}
