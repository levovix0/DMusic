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
  src/Track.cpp \
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
  src/api.hpp \
  src/file.hpp \
  src/nimfs.hpp \
  src/python.hpp \
  src/types.hpp \
  src/utils.hpp \
  src/yapi.hpp

RESOURCES += qml.qrc translations.qrc
win32:RC_ICONS += resources/app.ico

TRANSLATIONS += \
  translations/russian.ts

!isEmpty(TRANSLATIONS): contains(RESOURCES, translations.qrc) {
  # generate translations.qrc if TRANSLATIONS changed
  _old_translations = $$cat($$OUT_PWD/translations.txt)
  _current_translations = $$TRANSLATIONS
  _current_translations -= $$_old_translations
  _old_translations -= $$TRANSLATIONS
  _transaltions_diff = $$_old_translations $$_current_translations
  !isEmpty(_transaltions_diff)|!exists($$OUT_PWD/translations.txt)|!exists($$PWD/translations.qrc) {
    message(regenerating translations.qrc)

    # create translations.qrc
    _translations_qrc += <RCC><qresource prefix=\"/\">$$escape_expand(\n)
    for(_translation_name, TRANSLATIONS) {
      _translation_name_qm = $$section(_translation_name,".", 0, 0).qm
      _translations_qrc += <file>$$_translation_name_qm</file>$$escape_expand(\n)

      # if *.qm not exist - create dummy
      system($$shell_path($$[QT_INSTALL_BINS]/lrelease) $$shell_path($$PWD/$$_translation_name) -qm $$shell_path($$_translation_name_qm))
    }
    _translations_qrc += </qresource></RCC>$$escape_expand(\n)
    write_file($$PWD/translations.qrc, _translations_qrc)
    write_file($$OUT_PWD/translations.txt, TRANSLATIONS);

    QMAKE_CLEAN += $$shell_path($$OUT_PWD/translations.txt)
  }

  # run lrelease
  QMAKE_EXTRA_COMPILERS += _translations_lrelease
  _translations_lrelease.input = TRANSLATIONS
  _translations_lrelease.output = $$PWD/translations/${QMAKE_FILE_BASE}.qm
  _translations_lrelease.commands = $$[QT_INSTALL_BINS]/lrelease ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
  _translations_lrelease.CONFIG += no_link
}

QML_IMPORT_PATH =

QML_DESIGNER_IMPORT_PATH =

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
