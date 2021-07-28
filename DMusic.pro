QT += quick quickcontrols2 widgets multimedia dbus svg network

CONFIG += c++17

SOURCES += \
  src/AudioPlayer.cpp \
  src/Clipboard.cpp \
  src/Config.cpp \
  src/DFileDialog.cpp \
  src/Dir.cpp \
  src/Download.cpp \
  src/ID.cpp \
  src/MediaDownloader.cpp \
  src/Messages.cpp \
  src/Radio.cpp \
  src/RemoteMediaController.cpp \
  src/Track.cpp \
  src/Translator.cpp \
  src/api.cpp \
  src/main.cpp \
  src/python.cpp \
  src/yapi.cpp

HEADERS += \
  src/AudioPlayer.hpp \
  src/Clipboard.hpp \
  src/Config.hpp \
  src/ConsoleArgs.hpp \
  src/DFileDialog.hpp \
  src/Dir.hpp \
  src/Download.hpp \
  src/ID.hpp \
  src/MediaDownloader.hpp \
  src/Messages.hpp \
  src/Radio.hpp \
  src/RemoteMediaController.hpp \
  src/Track.hpp \
  src/Translator.hpp \
  src/api.hpp \
  src/file.hpp \
  src/nimfs.hpp \
  src/python.hpp \
  src/types.hpp \
  src/utils.hpp \
  src/yapi.hpp

RESOURCES += qml.qrc
win32:RC_ICONS += resources/app.ico

TRANSLATIONS += \
  translations/russian.ts

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

win32 {
  LIBS += -L$$(USERPROFILE)\AppData\Local\Programs\Python\Python39\libs -lpython39
  INCLUDEPATH += $$(USERPROFILE)\AppData\Local\Programs\Python\Python39\include
  DEPENDPATH += $$(USERPROFILE)\AppData\Local\Programs\Python\Python39\include
}

unix {
  LIBS += -L/usr/local/lib/python3.9 -lpython3.9
  INCLUDEPATH += /usr/include/python3.9
  DEPENDPATH += /usr/include/python3.9
}

DISTFILES += \
  src/codegen/genconfig.nim \
  src/config.nim
