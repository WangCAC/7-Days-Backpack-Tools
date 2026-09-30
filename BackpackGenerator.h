#pragma once

#include <QObject>
#include <QJsonObject>
#include <QList>
#include <QUrl>
#include <QVariantMap>

class BackpackGenerator : public QObject
{
    Q_OBJECT

public:
    explicit BackpackGenerator(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap layout(int capacity, int freeSlots) const;
    Q_INVOKABLE QUrl suggestedFileUrl(int capacity, int freeSlots) const;
    Q_INVOKABLE QVariantMap saveZip(int capacity, int freeSlots, const QUrl &destination) const;
    Q_INVOKABLE QVariantMap installMod(int capacity, int freeSlots, const QString &gameProgramPath) const;

private:
    struct Layout {
        int capacity = 0;
        int baseBagSize = 0;
        int maxCapacity = 0;
        int freeSlots = 0;
        int extra = 0;
        int cols = 0;
        int rows = 0;
        int gridRows = 0;
        int visibleRows = 0;
        int unused = 0;
        int cell = 0;
        int width = 0;
        int height = 0;
        int contentHeight = 0;
        double stackScale = 0;
        double interpolation = 0;
        QList<int> perk;
        QList<int> perkRank;
    };

    static Layout calculate(int capacity, int freeSlots);
    QString patchXml(const QString &relativePath, const QString &source,
                     const Layout &layout, QString *error) const;
    QString modInfo(const Layout &layout, const QString &folder) const;

    QJsonObject m_files;
    QJsonObject m_baseline;
    QString m_loadError;
    QVariantList m_loadErrorArgs;
};
