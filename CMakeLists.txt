cmake_minimum_required(VERSION 3.20)
project(typeshi VERSION 0.1.9)

option(FLATPAK_BUILD "Build for Flatpak packaging" OFF)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql WebSockets Multimedia)

qt_standard_project_setup()
qt_policy(SET QTP0004 NEW)

qt_add_executable(typeshi)

target_compile_definitions(typeshi PRIVATE
  TYPESHI_VERSION="${PROJECT_VERSION}"
)

set_source_files_properties(application/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)
set_source_files_properties(application/Shapes/GetMShapes.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)
file(GLOB_RECURSE QML_ABS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/application/*.qml")
file(GLOB_RECURSE JS_ABS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/application/*.js")
file(GLOB_RECURSE ASSET_FILES_ABS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/application/assets/*")

set(ASSET_FILES "")
foreach(_abs_path ${ASSET_FILES_ABS})
    file(RELATIVE_PATH _rel_path "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_path}")
    list(APPEND ASSET_FILES "${_rel_path}")
endforeach()

set(ALL_QML_MODULE_FILES "")
set(ALL_SRC_ABS ${QML_ABS} ${JS_ABS})
foreach(_abs_path ${ALL_SRC_ABS})
    file(RELATIVE_PATH _rel_path "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_path}")
    list(APPEND ALL_QML_MODULE_FILES "${_rel_path}")
endforeach()

qt_add_qml_module(typeshi
    URI typeShitter
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/typeShitter"
    NO_PLUGIN
    QML_FILES ${ALL_QML_MODULE_FILES}
    SOURCES
        Main.cpp
        ConfigManager.cpp
        ConfigManager.hpp
        TypingEngine.cpp
        TypingEngine.hpp
        HistoryManager.cpp
        HistoryManager.hpp
        ConfettiRenderer.cpp
        ConfettiRenderer.hpp
        QuoteManager.cpp
        QuoteManager.hpp
        MultiplayerClient.hpp
        MultiplayerClient.cpp
        ShootoutEngine.hpp
        ShootoutEngine.cpp
        FuzzyFinder.cpp
        FuzzyFinder.hpp
)

qt_add_resources(typeshi "assets"
    PREFIX "/qt/qml/typeShitter"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES ${ASSET_FILES}
)

target_include_directories(typeshi PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(typeshi PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Sql
    Qt6::WebSockets
    Qt6::Multimedia
)

qt_import_qml_plugins(typeshi)

install(TARGETS typeshi
  RUNTIME DESTINATION bin
)
if(FLATPAK_BUILD)
    install(FILES np.com.safallama.typeshi.desktop DESTINATION share/applications)
    install(FILES application/assets/typeShi.svg DESTINATION share/icons/hicolor/scalable/apps RENAME np.com.safallama.typeshi.svg)
    install(FILES np.com.safallama.typeshi.metainfo.xml DESTINATION share/metainfo)
else()
    install(FILES typeshi.desktop DESTINATION share/applications)
    install(FILES application/assets/typeShi.svg DESTINATION share/icons/hicolor/scalable/apps RENAME typeshi.svg)
endif()
