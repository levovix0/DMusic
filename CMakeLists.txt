cmake_minimum_required(VERSION 3.19)

project(DMusic VERSION 0.3 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick LinguistTools Quick QuickControls2 Widgets Multimedia DBus Svg Network REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick LinguistTools Quick QuickControls2 Widgets Multimedia DBus Svg Network REQUIRED)
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
find_package(Taglib REQUIRED)

set(TS_FILES translations/russian.ts)

set(all_sources )

macro(source_from_directory dir)
	aux_source_directory(${dir} tmpv)
	foreach(x IN LISTS tmpv)
		list(APPEND all_sources ${x})
	endforeach()
	include_directories(${dir})
endmacro()

source_from_directory(src)

set(PROJECT_SOURCES
  ${all_sources}
  qml.qrc
  ${TS_FILES}
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
  qt_add_executable(${PROJECT_NAME}
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
  )
  qt_create_translation(QM_FILES ${CMAKE_SOURCE_DIR}/translations ${TS_FILES})

else()
  if(ANDROID)
    add_library(${PROJECT_NAME} SHARED
      ${PROJECT_SOURCES}
    )
  else()
    add_executable(${PROJECT_NAME}
      ${PROJECT_SOURCES}
    )
  endif()

  qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR} ${TS_FILES})
endif()

if(UNIX)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
endif()

set(qt "Qt${QT_VERSION_MAJOR}")

target_compile_definitions(${PROJECT_NAME} PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(${PROJECT_NAME} PRIVATE
  ${qt}::Core
  ${qt}::Quick
  ${qt}::QuickControls2
  ${qt}::Widgets
  ${qt}::Multimedia
  ${qt}::DBus
  ${qt}::Svg
  ${qt}::Network
  ${Python3_LIBRARIES}
  ${Taglib_LIBRARIES}
)
include_directories(${Python3_INCLUDE_DIRS})
include_directories(${Taglib_INCLUDE_DIRS})

set_target_properties(${PROJECT_NAME} PROPERTIES
  MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
  MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

if(QT_VERSION_MAJOR EQUAL 6)
  qt_import_qml_plugins(${PROJECT_NAME})
  qt_finalize_executable(${PROJECT_NAME})
endif()
