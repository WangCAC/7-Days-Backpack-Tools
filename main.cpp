#include <QGuiApplication>
#include <QEvent>
#include <QFont>
#include <QFontDatabase>
#include <QIcon>
#include <QList>
#include <QMouseEvent>
#include <QPainter>
#include <QPointer>
#include <QPixmap>
#include <QQuickItem>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QSvgRenderer>
#include <QStringList>
#include <QTimer>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "BackpackGenerator.h"
#include "GameManager.h"
#include "LocalizationManager.h"
#include "ui/FocusDismissFilter.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle(QStringLiteral("Basic"));
    QCoreApplication::setOrganizationName("wangcac");
    QCoreApplication::setApplicationName("BackpackTools");
    QCoreApplication::setApplicationVersion(QStringLiteral("1.3.0"));
    const QStringList installedFonts = QFontDatabase::families();
    QString uiFontFamily;
    for (const QString &candidate : {QStringLiteral("Source Han Sans SC"),
                                     QStringLiteral("思源黑体"),
                                     QStringLiteral("Noto Sans SC")}) {
        for (const QString &installed : installedFonts) {
            if (installed.compare(candidate, Qt::CaseInsensitive) == 0) {
                uiFontFamily = installed;
                break;
            }
        }
        if (!uiFontFamily.isEmpty())
            break;
    }
    if (uiFontFamily.isEmpty())
        uiFontFamily = QStringLiteral("Microsoft YaHei UI");
    QFont uiFont = app.font();
    uiFont.setFamily(uiFontFamily);
    uiFont.setWeight(QFont::Medium);
    app.setFont(uiFont);
    QSvgRenderer logo(QStringLiteral(":/assets/backpack-logo.svg"));
    QIcon appIcon;
    for (int size : {32, 64, 128, 256}) {
        QPixmap pixmap(size, size);
        pixmap.fill(Qt::transparent);
        QPainter painter(&pixmap);
        logo.render(&painter);
        painter.end();
        appIcon.addPixmap(pixmap);
    }
    app.setWindowIcon(appIcon);

    LocalizationManager localization;
    BackpackGenerator generator;
    GameManager gameManager(&localization);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backpackGenerator", &generator);
    engine.rootContext()->setContextProperty("gameManager", &gameManager);
    engine.rootContext()->setContextProperty("localization", &localization);
    engine.rootContext()->setContextProperty("uiFontFamily", uiFontFamily);
    engine.rootContext()->setContextProperty("appVersion", QCoreApplication::applicationVersion());
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("BackpackTools", "Main");

    if (!engine.rootObjects().isEmpty()) {
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
        if (window && window->contentItem()) {
            QList<QQuickItem *> focusFields;
            for (const char *name : {"capacityInput", "freeInput", "backpackInput", "gameCombo",
                                     "previewTypeCombo", "previewQualityCombo", "previewPerkCombo"}) {
                if (auto *field = window->contentItem()->findChild<QQuickItem *>(QString::fromLatin1(name)))
                    focusFields.append(field);
            }
            if (!focusFields.isEmpty()) {
                auto *focusFilter = new FocusDismissFilter(window, focusFields);
                window->installEventFilter(focusFilter);
            }
        }
    }

    return app.exec();
}
