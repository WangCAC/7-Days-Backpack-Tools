#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "BackpackGenerator.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    BackpackGenerator generator;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backpackGenerator", &generator);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("BackpackTools", "Main");

    return app.exec();
}
