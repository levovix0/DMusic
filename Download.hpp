#pragma once
#include <QObject>
#include <QByteArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class Download : public QObject
{
  Q_OBJECT
public:
  Download(QUrl url, QObject* parent = nullptr);
  virtual ~Download();

signals:
  void finished(QByteArray data);

private slots:
  void onFinished(QNetworkReply* reply);

private:
  QNetworkAccessManager _networkControl;
};
