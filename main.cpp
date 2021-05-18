#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QTranslator>
#include "yapi.hpp"
#include "file.hpp"
#include "settings.hpp"
#include "AudioPlayer.hpp"
#include "RemoteMediaController.hpp"
#include "Clipboard.hpp"
#include "DFileDialog.hpp"
#include "Messages.hpp"
#include "ConsoleArgs.hpp"

int main(int argc, char *argv[])
{
  ConsoleArgs args(argc, argv);

  Py_Initialize();

  QTranslator translator;
  translator.load(":translations/russian");

  QGuiApplication app(argc, argv);
  app.installTranslator(&translator);

  bool gui = args.count() == 0 || args.has("-g") || args.has("--gui");

  if (args.has("-v") || args.has("--version")) {
    std::cout << "DMusic 0.1" << std::endl;
  }

  if (args.has("-h") || args.has("--help")) {
    std::cout << QObject::tr(
"DMusic - music player\n"
"usage: %1 [options]\n\n"
"-h --help     show help\n"
"-v --version  show version\n"
"-g --gui      run application\n"
"-verbose      show more logs\n"
    ).arg(argv[0]) << std::endl;
  }

  if (!args.has("--verbose")) {
    try {
      auto logging = py::module("logging");
      auto logger = logging.call("getLogger");
      logger.call("setLevel", logging.get("CRITICAL"));
    } catch (py::error& e) {
      Messages::error("a", e.what());
    }
  }

//  if (!gui) return 0;

  qmlRegisterType<YTrack>("DMusic", 1, 0, "YTrack");
  qmlRegisterType<YArtist>("DMusic", 1, 0, "YArtist");
  qmlRegisterType<YTrack>("DMusic", 1, 0, "Track");
  qmlRegisterType<Playlist>("DMusic", 1, 0, "Playlist");
  qmlRegisterType<DPlaylist>("DMusic", 1, 0, "DPlaylist");
  qmlRegisterType<AudioPlayer>("DMusic", 1, 0, "AudioPlayer");
  qmlRegisterType<Settings>("DMusic", 1, 0, "Settings");
  qmlRegisterType<RemoteMediaController>("DMusic", 1, 0, "RemoteMediaController");
  qmlRegisterType<Clipboard>("DMusic", 1, 0, "Clipboard");
  qmlRegisterType<DFileDialog>("DMusic", 1, 0, "DFileDialog");

  qmlRegisterSingletonType<Messages>("DMusic", 1, 0, "Messages", &Messages::qmlInstance);
  qmlRegisterSingletonType<YClient>("DMusic", 1, 0, "YClient", &YClient::qmlInstance);

#ifdef Q_OS_LINUX
  QGuiApplication::setWindowIcon(QIcon(":resources/app-papirus.svg"));
#else
  QGuiApplication::setWindowIcon(QIcon(":resources/app.svg"));
#endif
  app.setApplicationName("DMusic");
  app.setOrganizationName("DTeam");
  app.setOrganizationDomain("zxx.ru");

  QQmlApplicationEngine engine;
  engine.load(QUrl("qrc:/main.qml"));

  auto r = app.exec();
  Py_Finalize();
  return r;
}
