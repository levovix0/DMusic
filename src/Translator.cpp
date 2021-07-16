#include "Translator.hpp"

Translator::Translator(QObject *parent) : QObject(parent)
{

}

Translator* Translator::instance = new Translator;

void Translator::setApp(QApplication* app)
{
	instance->_app = app;
}

void Translator::setEngine(QQmlEngine* engine)
{
	instance->_engine = engine;
}

void Translator::setLanguage(Config::Language language)
{
	if (!_translator.isEmpty())
		_app->removeTranslator(&_translator);
	if (!toString(language).isEmpty()) {
		_translator.load(toString(language));
		_app->installTranslator(&_translator);
	}

	if (_engine) _engine->retranslate();
}
