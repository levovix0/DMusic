#pragma once
#include <QObject>
#include <QMediaContent>
#include "Download.hpp"

class MediaDownloader : public QObject
{
  Q_OBJECT
public:
  MediaDownloader(QUrl url, QObject *parent = nullptr);

signals:
  void finished(QMediaContent media);

private slots:
  void onFinished(QByteArray data);

private:
  Download _download;
};

