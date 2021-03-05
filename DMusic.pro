QT += quick multimedia

CONFIG += c++17

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0


win32 { HOME = $$system(echo %HOME%) }
unix { HOME = $$system(echo $HOME) }


SOURCES += \
        main.cpp \
        yapi.cpp

RESOURCES += qml.qrc

TRANSLATIONS += \
    DMusic_ru_RU.ts


# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
  file.hpp \
  python.hpp \
  settings.hpp \
  utils.hpp \
  yapi.hpp


win32: LIBS += -L$$HOME/scoop/apps/python/current/libs/ -lpython39

INCLUDEPATH += $$HOME/scoop/apps/python/current/include
DEPENDPATH += $$HOME/scoop/apps/python/current/include

#win32:!win32-g++: PRE_TARGETDEPS += $$HOME/scoop/apps/python/current/libs/python3.lib
#else:win32-g++: PRE_TARGETDEPS += $$HOME/scoop/apps/python/current/libs/libpython3.a


unix {
  LIBS += -L/usr/local/lib/python3.9 -lpython3.9
  INCLUDEPATH += /usr/include/python3.9
  DEPENDPATH += /usr/include/python3.9
}
