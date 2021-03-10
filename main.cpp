#include <yapi.hpp>
#include <file.hpp>
#include <settings.hpp>
#include <mediaplayer.hpp>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[])
{
  Py_Initialize();
  QGuiApplication app(argc, argv);
  qmlRegisterType<YClient>("yapi", 1, 0, "YClient");
  qmlRegisterType<YTrack>("yapi", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("yapi", 1, 0, "YArtist");
  qmlRegisterType<YTrack>("api", 1, 0, "Track");
  qmlRegisterType<MediaPlayer>("api", 1, 0, "MediaPlayer");
  qmlRegisterType<Settings>("api", 1, 0, "Settings");

  QGuiApplication::setWindowIcon(QIcon("application.svg"));
  app.setApplicationName("DMusic");

  QQmlApplicationEngine engine;
  engine.load(QUrl("qrc:/main.qml"));

  auto r = app.exec();
  Py_Finalize();
  return r;
}
