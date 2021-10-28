#include "main.hpp"

#include <QApplication>
#include <QIcon>
#include <QTimer>
#include "YandexMusic.hpp"
#include "Config.hpp"
#include "AudioPlayer.hpp"
#include "RemoteMediaController.hpp"
#include "Clipboard.hpp"
#include "DFileDialog.hpp"
#include "Translator.hpp"


void initializeDMusicQmlModule() {
  qmlRegisterType<Track>("DMusic", 1, 0, "Track");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("DMusic", 1, 0, "YArtist");
  qmlRegisterType<Playlist>("DMusic", 1, 0, "Playlist");
  qmlRegisterType<DPlaylist>("DMusic", 1, 0, "DPlaylist");
  qmlRegisterType<Radio>("DMusic", 1, 0, "Radio");
  qmlRegisterType<PlaylistRadio>("DMusic", 1, 0, "PlaylistRadio");
  qmlRegisterType<AudioPlayer>("DMusic", 1, 0, "AudioPlayer");
  qmlRegisterType<RemoteMediaController>("DMusic", 1, 0, "RemoteMediaController");
  qmlRegisterType<Clipboard>("DMusic", 1, 0, "Clipboard");
  qmlRegisterType<DFileDialog>("DMusic", 1, 0, "DFileDialog");
  qmlRegisterType<YPlaylist>("DMusic", 1, 0, "YPlaylist");
  qmlRegisterType<YLikedTracks>("DMusic", 1, 0, "YLikedTracks");
  qmlRegisterType<YPlaylistsModel>("DMusic", 1, 0, "YPlaylistsModel");

	qmlRegisterSingletonType<Config>("DMusic", 1, 0, "Config", &Config::qmlInstance);
	qmlRegisterSingletonType<Config>("Config", 1, 0, "Config", &Config::qmlInstance);
	qmlRegisterSingletonType<Translator>("DMusic", 1, 0, "Translator", &Config::qmlInstance);
  qmlRegisterSingletonType<YClient>("DMusic", 1, 0, "YClient", &YClient::qmlInstance);

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
