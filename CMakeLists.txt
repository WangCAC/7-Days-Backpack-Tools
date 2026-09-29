cmake_minimum_required(VERSION 3.16)

project(BackpackTools VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Xml)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appBackpackTools
    main.cpp
    BackpackGenerator.cpp
    BackpackGenerator.h
)

qt_add_resources(appBackpackTools "backpack_templates"
    PREFIX "/"
    FILES backpack_templates.json
)

qt_add_qml_module(appBackpackTools
    URI BackpackTools
    VERSION 1.0
    QML_FILES
        Main.qml
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
    PRIVATE Qt6::Quick Qt6::Xml
)

include(GNUInstallDirs)
install(TARGETS appBackpackTools
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
