QT += quick quickcontrols2 widgets multimedia dbus svg network
win32: QT += winextras

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
  src/SearchHistory.cpp \
  src/TagLib.cpp \
  src/Track.cpp \
  src/Translator.cpp \
  src/YandexMusic.cpp \
  src/api.cpp \
  src/main.cpp \
  src/python.cpp

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
  src/SearchHistory.hpp \
  src/TagLib.hpp \
  src/Track.hpp \
  src/Translator.hpp \
  src/YandexMusic.hpp \
  src/api.hpp \
  src/file.hpp \
  src/nimfs.hpp \
  src/python.hpp \
  src/types.hpp \
  src/utils.hpp

RESOURCES += qml.qrc
win32:RC_ICONS += resources/app.ico

TRANSLATIONS += \
  translations/russian.ts

QMAKE_EXTRA_COMPILERS += _translations
_translations.input = TRANSLATIONS
_translations.output = $$PWD/translations/russian.qm
_translations.commands = $$[QT_INSTALL_BINS]/lrelease ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
_translations.CONFIG += no_link

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

win32 {
  LIBS += -L$$(USERPROFILE)\AppData\Local\Programs\Python\Python39\libs -lpython39
  INCLUDEPATH += $$(USERPROFILE)\AppData\Local\Programs\Python\Python39\include
  DEPENDPATH += $$(USERPROFILE)\AppData\Local\Programs\Python\Python39\include
}

unix {
  LIBS += -L/usr/local/lib/python3.9 -lpython3.9 -ltag
  INCLUDEPATH += /usr/include/python3.9
  DEPENDPATH += /usr/include/python3.9
}

DISTFILES += \
  src/codegen/genconfig.nim \
  src/config.nim

DEFINES += TAGLIB_STATIC

win32 {
  CONFIG(release, debug|release): LIBS += -L"C:/Program Files/taglib/lib/" -ltag -lz
  INCLUDEPATH += "C:/Program Files/taglib/include"
  DEPENDPATH += "C:/Program Files/taglib/include"
}
