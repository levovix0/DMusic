#include <yapi.hpp>
#include <QGuiApplication>
#include <QQmlApplicationEngine>


int main(int argc, char *argv[])
{
  QGuiApplication app(argc, argv);
	qmlRegisterType<Yapi>("yapi", 1, 0, "Yapi");

  QQmlApplicationEngine engine;
  const QUrl url(QStringLiteral("qrc:/main.qml"));
  engine.load(url);

  return app.exec();
}
