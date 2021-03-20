#include "yapi.hpp"
#include "file.hpp"
#include "settings.hpp"
#include "mediaplayer.hpp"
#include "RemoteMediaController.hpp"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
  Py_Initialize();
  QGuiApplication app(argc, argv);
  qmlRegisterType<YClient>("DMusic", 1, 0, "YClient");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("DMusic", 1, 0, "YArtist");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "Track");
  qmlRegisterType<Playlist>("DMusic", 1, 0, "Playlist");
  qmlRegisterType<DPlaylist>("DMusic", 1, 0, "DPlaylist");
  qmlRegisterType<MediaPlayer>("DMusic", 1, 0, "MediaPlayer");
  qmlRegisterType<Settings>("DMusic", 1, 0, "Settings");
  qmlRegisterType<RemoteMediaController>("DMusic", 1, 0, "RemoteMediaController");

  QGuiApplication::setWindowIcon(QIcon("application.svg"));
  app.setApplicationName("DMusic");

  QQmlApplicationEngine engine;
  engine.load(QUrl("qrc:/main.qml"));

  auto r = app.exec();
  Py_Finalize();
  return r;
}
