#include "main.hpp"

#include <QApplication>
#include <QIcon>
#include <QTimer>
#include "Config.hpp"
#include "Translator.hpp"


void initializeDMusicQmlModule() {
	qmlRegisterSingletonType<Config>("DMusic", 1, 0, "Config", &Config::qmlInstance);
	qmlRegisterSingletonType<Config>("Config", 1, 0, "Config", &Config::qmlInstance);
	qmlRegisterSingletonType<Translator>("DMusic", 1, 0, "Translator", &Config::qmlInstance);

  qmlRegisterSingletonType(QUrl("qrc:/qml/StyleSingleton.qml"), "DMusic", 1, 0, "Style");
}

void cppmain()
{
	Translator::instance->setLanguage(Config::language());
	QObject::connect(Config::instance, &Config::languageChanged, [](Config::Language language) {
		Translator::instance->setLanguage(language);
	});

  auto updateThemeIfNeeded = []() {
    if (!Config::themeByTime()) return;
    if (QTime::currentTime().hour() >= 19 || QTime::currentTime().hour() < 7) {
      if (!Config::instance->darkTheme()) {
        Config::instance->setDarkTheme(true);
      }
    } else if (Config::instance->darkTheme()) {
      Config::instance->setDarkTheme(false);
    }
  };
  QObject::connect(Config::instance, &Config::themeByTimeChanged, updateThemeIfNeeded);

  bool darkTime = Config::instance->darkTheme();
  auto timer = new QTimer();
  QObject::connect(timer, &QTimer::timeout, [&](){
    if (!Config::themeByTime()) return;
    if (QTime::currentTime().hour() >= 19 || QTime::currentTime().hour() < 7) {
      if (!darkTime) {
        Config::instance->setDarkTheme(true);
        darkTime = true;
      }
    } else if (darkTime) {
      Config::instance->setDarkTheme(false);
      darkTime = false;
    }
  });
  timer->start(1000);


  QObject::connect(Config::instance, &Config::isClientSideDecorationsChanged, []() {
#ifdef Q_OS_LINUX
    QApplication::setWindowIcon(QIcon(":resources/app-papirus.svg"));
#else
    QApplication::setWindowIcon(QIcon(":resources/app.svg"));
#endif
  });

#ifdef Q_OS_LINUX
  QApplication::setWindowIcon(QIcon(":resources/app-papirus.svg"));
#else
  QApplication::setWindowIcon(QIcon(":resources/app.svg"));
#endif
};
