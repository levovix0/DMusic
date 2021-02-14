#pragma once

#define PY_SSIZE_T_CLEAN
#include <Python.h>
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

signals:

};
