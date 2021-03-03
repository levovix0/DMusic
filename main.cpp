#include <yapi.hpp>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
  Py_Initialize();
  QGuiApplication app(argc, argv);
  qmlRegisterType<YClient>("yapi", 1, 0, "YClient");
  qmlRegisterType<YTrack>("yapi", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("yapi", 1, 0, "YArtist");
  qRegisterMetaType<YTrack>("YTrack");
  qRegisterMetaType<YArtist>("YArtist");

  QQmlApplicationEngine engine;
  const QUrl url(QStringLiteral("qrc:/main.qml"));
  engine.load(url);

  auto r = app.exec();
  Py_Finalize();
  return r;
}
