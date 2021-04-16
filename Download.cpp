#include "Download.hpp"

Download::Download(QUrl url, QObject* parent) : QObject(parent)
{
 connect(&_networkControl, &QNetworkAccessManager::finished, this, &Download::onFinished);
 _networkControl.get(QNetworkRequest(url));
}

Download::~Download()
{

}

void Download::onFinished(QNetworkReply* reply)
{
 reply->deleteLater();
 emit finished(reply->readAll());
}
