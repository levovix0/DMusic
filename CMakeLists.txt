cmake_minimum_required(VERSION 3.14)

project(DMusic LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# QtCreator supports the following variables for Android, which are identical to qmake Android variables.
# Check https://doc.qt.io/qt/deployment-android.html for more information.
# They need to be set before the find_package(...) calls below.

#if(ANDROID)
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
#    if (ANDROID_ABI STREQUAL "armeabi-v7a")
#        set(ANDROID_EXTRA_LIBS
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libcrypto.so
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libssl.so)
#    endif()
#endif()

find_package(Python3 COMPONENTS Development REQUIRED)

set(qt_winextras )
if(WIN32)
  set(qt_winextras WinExtras)
endif()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick LinguistTools Multimedia DBus ${qt_winextras} REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick LinguistTools Multimedia DBus ${qt_winextras} REQUIRED)

set(TS_FILES ${PROJECT_NAME}_ru_RU.ts)

file(GLOB PROJECT_SOURCES "*.cpp")
file(GLOB project_headers "*.hpp")
file(GLOB project_qml "*.qml")
set(PROJECT_SOURCES ${PROJECT_SOURCES} ${TS_FILES})

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(${PROJECT_NAME} ${PROJECT_SOURCES} ${project_headers} qml.qrc)

    qt_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
else()
    if(ANDROID)
        add_library(${PROJECT_NAME} SHARED ${PROJECT_SOURCES} ${project_headers} qml.qrc)
    else()
        add_executable(${PROJECT_NAME} ${PROJECT_SOURCES} ${project_headers} qml.qrc)
    endif()

    qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
endif()

target_compile_definitions(${PROJECT_NAME} PRIVATE
  $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
)

target_link_libraries(${PROJECT_NAME} PRIVATE
  ${Python3_LIBRARIES}
  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Quick
  Qt${QT_VERSION_MAJOR}::Multimedia
  Qt${QT_VERSION_MAJOR}::DBus
)
if(WIN32)
  target_link_libraries(${PROJECT_NAME} PRIVATE Qt${QT_VERSION_MAJOR}::WinExtras)
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${Python3_INCLUDE_DIRS})
