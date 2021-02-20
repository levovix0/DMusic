#pragma once
#include "python.hpp"
#include <QObject>

class Yapi : public QObject
{
	Q_OBJECT
public:
	explicit Yapi(QObject *parent = nullptr);
	~Yapi();

//	Q_INVOKABLE QString* token(QString login, QString password);
//	Q_INVOKABLE void login(QString token);

  Q_INVOKABLE void download(QString id);
  Q_INVOKABLE QString test(QString a);

signals:

private:
  py::object ym; // yandex_music module

  py::object me; // client
};
