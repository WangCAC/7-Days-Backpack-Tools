#include "LocalizationManager.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>

LocalizationManager::LocalizationManager(QObject *parent) : QObject(parent)
{
    setLanguage(QLocale::system().language() == QLocale::Chinese
                    ? QStringLiteral("zh_CN") : QStringLiteral("en_US"));
}

void LocalizationManager::setLanguage(const QString &language)
{
    if (language != QStringLiteral("zh_CN") && language != QStringLiteral("en_US"))
        return;
    if (m_language == language)
        return;

    QFile file(QStringLiteral(":/locales/") + language + QStringLiteral(".json"));
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject())
        return;

    m_language = language;
    m_strings = document.object().toVariantMap();
    emit languageChanged();
}

QString LocalizationManager::text(const QString &key, const QVariantList &arguments) const
{
    QString result = m_strings.value(key, key).toString();
    for (const QVariant &argument : arguments)
        result = result.arg(argument.toString());
    return result;
}
