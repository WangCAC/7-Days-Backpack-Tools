#pragma once

#include <QObject>
#include <QVariantMap>

class LocalizationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language NOTIFY languageChanged)
    Q_PROPERTY(QVariantMap strings READ strings NOTIFY languageChanged)

public:
    explicit LocalizationManager(QObject *parent = nullptr);

    QString language() const { return m_language; }
    QVariantMap strings() const { return m_strings; }
    QString text(const QString &key, const QVariantList &arguments = {}) const;
    Q_INVOKABLE void setLanguage(const QString &language);

signals:
    void languageChanged();

private:
    QString m_language;
    QVariantMap m_strings;
};
