#include "MediaDownloader.hpp"


MediaDownloader::MediaDownloader(QUrl url, QObject* parent) : QObject(parent), _download(url)
{
  connect(&_download, &Download::finished, this, &MediaDownloader::onFinished);
}

void MediaDownloader::onFinished(QByteArray data)
{
}
