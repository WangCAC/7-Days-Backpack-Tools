#pragma once

#include <QEvent>
#include <QList>
#include <QMouseEvent>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTimer>

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
