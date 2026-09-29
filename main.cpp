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
#include <QSvgRenderer>
#include <QStringList>
#include <QTimer>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "BackpackGenerator.h"
#include "GameManager.h"
#include "LocalizationManager.h"

class FocusDismissFilter final : public QObject
{
public:
    FocusDismissFilter(QQuickWindow *window, const QList<QQuickItem *> &fields)
        : QObject(window), m_window(window)
    {
        for (QQuickItem *field : fields)
            m_fields.append(field);
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (watched != m_window.data() || event->type() != QEvent::MouseButtonRelease)
            return false;

        const auto *mouse = static_cast<QMouseEvent *>(event);
        if (mouse->button() != Qt::LeftButton)
            return false;

        const QPointF position = mouse->position();
        for (const QPointer<QQuickItem> &field : m_fields) {
            if (field && field->contains(field->mapFromScene(position)))
                return false;
        }

        // Run after the clicked control has processed the release. This avoids
        // taking focus away from another control that legitimately received it.
        QTimer::singleShot(0, m_window.data(),
                           [window = m_window, fields = m_fields]() {
            if (!window || !window->contentItem())
                return;
            bool dismissed = false;
            for (const QPointer<QQuickItem> &field : fields) {
                if (field && field->hasActiveFocus()) {
                    field->setFocus(false);
                    dismissed = true;
                }
            }
            if (dismissed)
                window->contentItem()->forceActiveFocus(Qt::MouseFocusReason);
        });
        return false;
    }

private:
    QPointer<QQuickWindow> m_window;
    QList<QPointer<QQuickItem>> m_fields;
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("wangcac");
    QCoreApplication::setApplicationName("BackpackTools");
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));
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
            for (const char *name : {"capacityInput", "freeInput", "gameCombo"}) {
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
