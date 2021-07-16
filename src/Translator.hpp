#pragma once
#include <QObject>
#include <QQmlEngine>
#include <QJSEngine>
#include <QTranslator>
#include <QApplication>
#include "Config.hpp"

class Translator : public QObject
{
	Q_OBJECT
public:
	explicit Translator(QObject *parent = nullptr);

	static Translator* instance;
	static Translator* qmlInstance(QQmlEngine*, QJSEngine*);

	static void setApp(QApplication* app);
	static void setEngine(QQmlEngine* engine);

public slots:
	void setLanguage(Config::Language language);

private:
	QTranslator _translator;
	QApplication* _app = nullptr;
	QQmlEngine* _engine = nullptr;
};

