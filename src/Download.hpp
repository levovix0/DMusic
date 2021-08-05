#pragma once
#include <QObject>
#include <QByteArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

class Download : public QObject
{
  //TODO: use c++20 coroutines instead of Qt slots and signals
  Q_OBJECT
public:
  Download(QObject* parent = nullptr);
  Download(QUrl const& url, QObject* parent = nullptr);
  virtual ~Download();

  void start(QUrl const& url);

signals:
  void finished(QByteArray data);

private slots:
  void onFinished(QNetworkReply* reply);

private:
  QNetworkAccessManager _networkControl;
};
