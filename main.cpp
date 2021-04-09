#include "yapi.hpp"
#include "file.hpp"
#include "settings.hpp"
#include "mediaplayer.hpp"
#include "Log.hpp"
#include "RemoteMediaController.hpp"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QTranslator>

int main(int argc, char *argv[])
{
  Py_Initialize();

  QTranslator translator;
  translator.load(":translations/russian");

  QGuiApplication app(argc, argv);
  app.installTranslator(&translator);

  qmlRegisterType<YClient>("DMusic", 1, 0, "YClient");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("DMusic", 1, 0, "YArtist");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "Track");
  qmlRegisterType<Playlist>("DMusic", 1, 0, "Playlist");
  qmlRegisterType<DPlaylist>("DMusic", 1, 0, "DPlaylist");
  qmlRegisterType<MediaPlayer>("DMusic", 1, 0, "MediaPlayer");
  qmlRegisterType<Settings>("DMusic", 1, 0, "Settings");
  qmlRegisterType<RemoteMediaController>("DMusic", 1, 0, "RemoteMediaController");

#ifdef Q_OS_LINUX
  QGuiApplication::setWindowIcon(QIcon(":resources/app-papirus.svg"));
#else
  QGuiApplication::setWindowIcon(QIcon(":resources/app.svg"));
#endif
  app.setApplicationName("DMusic");

  QQmlApplicationEngine engine;
  engine.load(QUrl("qrc:/main.qml"));

  auto r = app.exec();
  Py_Finalize();
  return r;
}
