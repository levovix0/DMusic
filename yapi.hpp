#pragma once
#include "python.hpp"
#include <QObject>
#include <atomic>

class Yapi : public QObject
{
	Q_OBJECT
public:
	explicit Yapi(QObject *parent = nullptr);
	~Yapi();

  Q_INVOKABLE bool isLoggined();

  Q_INVOKABLE QString token(QString login, QString password);
  Q_INVOKABLE void login(QString token);
  Q_INVOKABLE void login(QString token, QString proxy);

  Q_INVOKABLE void download(int id, QString outDir);
  Q_INVOKABLE void downloadInfo(int id, QString outDir);

signals:
  void loggedIn(bool success);
  void downloaded(int id, bool success);
  void downloadedInfo(int id, bool success);

private:
  py::object ym; // yandex_music module
  py::object ym_request;

  py::object me; // client
  py::object track;

  std::atomic_bool loggined;
};
