cmake_minimum_required(VERSION 3.16)

project(BackpackTools VERSION 1.0.5 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Xml Concurrent Gui Svg)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appBackpackTools
    main.cpp
    BackpackGenerator.cpp
    BackpackGenerator.h
    GameManager.cpp
    GameManager.h
    LocalizationManager.cpp
    LocalizationManager.h
)

if(WIN32)
    enable_language(RC)
    target_sources(appBackpackTools PRIVATE assets/app-icon.rc)
endif()

qt_add_resources(appBackpackTools "backpack_templates"
    PREFIX "/"
    FILES backpack_templates.json
)

qt_add_resources(appBackpackTools "locales"
    PREFIX "/"
    FILES locales/zh_CN.json locales/en_US.json
)

qt_add_resources(appBackpackTools "branding"
    PREFIX "/"
    FILES assets/backpack-logo.svg assets/help-circle.svg
          assets/language-globe.svg assets/chevron-down.svg
)

qt_add_qml_module(appBackpackTools
    URI BackpackTools
    VERSION 1.0
    QML_FILES
        Main.qml
        FluentButton.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appBackpackTools PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appBackpackTools
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appBackpackTools
    PRIVATE Qt6::Quick Qt6::Xml Qt6::Concurrent Qt6::Gui Qt6::Svg
)

include(GNUInstallDirs)
install(TARGETS appBackpackTools
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
