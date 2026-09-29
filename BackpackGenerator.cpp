#include "BackpackGenerator.h"

#include <QDateTime>
#include <QDomDocument>
#include <QFile>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QtMath>

#include <algorithm>

namespace {
struct ZipEntry {
    QString name;
    QByteArray body;
};

void append16(QByteArray &bytes, quint16 value)
{
    bytes.append(char(value & 0xff));
    bytes.append(char((value >> 8) & 0xff));
}

void append32(QByteArray &bytes, quint32 value)
{
    append16(bytes, quint16(value & 0xffff));
    append16(bytes, quint16(value >> 16));
}

quint32 crc32(const QByteArray &bytes)
{
    quint32 crc = 0xffffffffu;
    for (unsigned char value : bytes) {
        crc ^= value;
        for (int bit = 0; bit < 8; ++bit)
            crc = (crc >> 1) ^ ((crc & 1u) ? 0xedb88320u : 0u);
    }
    return crc ^ 0xffffffffu;
}

QString interpolateText(const QString &base, const QString &reference, double t)
{
    static const QRegularExpression number(QStringLiteral("^-?\\d+(?:\\.\\d+)?$"));
    const QStringList before = base.split(u',');
    const QStringList after = reference.split(u',');
    if (before.size() != after.size())
        return reference;

    QStringList result;
    for (int i = 0; i < before.size(); ++i) {
        const QString a = before.at(i).trimmed();
        const QString b = after.at(i).trimmed();
        if (!number.match(a).hasMatch() || !number.match(b).hasMatch())
            return reference;
        result.append(QString::number(qRound(a.toDouble() + (b.toDouble() - a.toDouble()) * t)));
    }
    return result.join(u',');
}

QByteArray createZip(const QList<ZipEntry> &entries)
{
    QByteArray output;
    QByteArray central;
    const QDateTime now = QDateTime::currentDateTime();
    const QDate date = now.date();
    const QTime time = now.time();
    const quint16 dosTime = quint16((time.hour() << 11) | (time.minute() << 5) | (time.second() / 2));
    const quint16 dosDate = quint16(((std::clamp(date.year(), 1980, 2107) - 1980) << 9)
                                    | (date.month() << 5) | date.day());

    for (const ZipEntry &entry : entries) {
        const QByteArray name = entry.name.toUtf8();
        const quint32 offset = quint32(output.size());
        const quint32 size = quint32(entry.body.size());
        const quint32 crc = crc32(entry.body);

        append32(output, 0x04034b50u);
        append16(output, 20);          // ZIP 2.0
        append16(output, 0x0800);      // UTF-8 names
        append16(output, 0);           // stored, no compression
        append16(output, dosTime);
        append16(output, dosDate);
        append32(output, crc);
        append32(output, size);
        append32(output, size);
        append16(output, quint16(name.size()));
        append16(output, 0);
        output.append(name);
        output.append(entry.body);

        append32(central, 0x02014b50u);
        append16(central, 20);
        append16(central, 20);
        append16(central, 0x0800);
        append16(central, 0);
        append16(central, dosTime);
        append16(central, dosDate);
        append32(central, crc);
        append32(central, size);
        append32(central, size);
        append16(central, quint16(name.size()));
        append16(central, 0);
        append16(central, 0);
        append16(central, 0);
        append16(central, 0);
        append32(central, 0);
        append32(central, offset);
        central.append(name);
    }

    const quint32 centralOffset = quint32(output.size());
    output.append(central);
    append32(output, 0x06054b50u);
    append16(output, 0);
    append16(output, 0);
    append16(output, quint16(entries.size()));
    append16(output, quint16(entries.size()));
    append32(output, quint32(central.size()));
    append32(output, centralOffset);
    append16(output, 0);
    return output;
}
}

BackpackGenerator::BackpackGenerator(QObject *parent) : QObject(parent)
{
    QFile source(QStringLiteral(":/backpack_templates.json"));
    if (!source.open(QIODevice::ReadOnly)) {
        m_loadError = QStringLiteral("无法读取内置模组模板。");
        return;
    }
    QJsonParseError parseError;
    const QJsonDocument data = QJsonDocument::fromJson(source.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !data.isObject()) {
        m_loadError = QStringLiteral("模组模板格式错误：%1").arg(parseError.errorString());
        return;
    }
    m_files = data.object().value(QStringLiteral("files")).toObject();
    m_baseline = data.object().value(QStringLiteral("baseline")).toObject();
    if (m_files.size() != 9)
        m_loadError = QStringLiteral("内置模组模板不完整。");
}

BackpackGenerator::Layout BackpackGenerator::calculate(int capacity, int freeSlots)
{
    Layout result;
    result.capacity = capacity;
    result.freeSlots = freeSlots;
    result.extra = capacity - freeSlots;

    double bestScore = 1e100;
    for (int cols = 8; cols <= 25; ++cols) {
        const int rows = (capacity + cols - 1) / cols;
        const int unused = cols * rows - capacity;
        const double score = unused * 1.5 + qAbs(rows - 10) * 2
                             + (rows < 5 ? (5 - rows) * 2 : 0);
        if (score < bestScore || (score == bestScore && cols < result.cols)) {
            bestScore = score;
            result.cols = cols;
            result.rows = rows;
            result.unused = unused;
        }
    }

    result.cell = qRound(73.0 - (result.cols - 8) * 7.0 / 17.0);
    result.width = result.cols * result.cell + qRound(19.0 + (result.cols - 8) * 9.0 / 17.0);
    result.contentHeight = qMin(result.rows, 10) * result.cell + 11;
    result.height = result.contentHeight + 46;
    result.interpolation = std::clamp((result.width - 603.0) / (1678.0 - 603.0), 0.0, 1.0);
    result.stackScale = qRound((1.05 + (0.75 - 1.05) * result.interpolation) * 100.0) / 100.0;

    const double fractions[5] = {10.0 / 125.0, 35.0 / 125.0, 70.0 / 125.0,
                                 95.0 / 125.0, 1.0};
    for (int level = 0; level < 5; ++level) {
        int value = level == 4 ? result.extra : qRound(result.extra * fractions[level]);
        if (!result.perk.isEmpty())
            value = qMax(value, result.perk.last());
        result.perk.append(value);
    }
    return result;
}

QVariantMap BackpackGenerator::layout(int capacity, int freeSlots) const
{
    if (capacity < 1 || capacity > 5000 || freeSlots < 0 || freeSlots > capacity)
        return {{QStringLiteral("valid"), false}};

    const Layout data = calculate(capacity, freeSlots);
    QVariantList perk;
    for (int value : data.perk)
        perk.append(value);
    return {{QStringLiteral("valid"), true},
            {QStringLiteral("capacity"), data.capacity},
            {QStringLiteral("free"), data.freeSlots},
            {QStringLiteral("extra"), data.extra},
            {QStringLiteral("cols"), data.cols},
            {QStringLiteral("rows"), data.rows},
            {QStringLiteral("unused"), data.unused},
            {QStringLiteral("cell"), data.cell},
            {QStringLiteral("width"), data.width},
            {QStringLiteral("height"), data.height},
            {QStringLiteral("contentHeight"), data.contentHeight},
            {QStringLiteral("stackScale"), data.stackScale},
            {QStringLiteral("perk"), perk}};
}

QUrl BackpackGenerator::suggestedFileUrl(int capacity, int freeSlots) const
{
    const QString name = QStringLiteral("wangcac-%1BigBackpack%2WB.zip").arg(capacity).arg(freeSlots);
    QString directory = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (directory.isEmpty())
        directory = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    return QUrl::fromLocalFile(directory + u'/' + name);
}

QString BackpackGenerator::patchXml(const QString &relativePath, const QString &source,
                                    const Layout &layout, QString *error) const
{
    QDomDocument document;
    QString parseMessage;
    int line = 0;
    int column = 0;
    if (!document.setContent(source, &parseMessage, &line, &column)) {
        *error = QStringLiteral("%1 模板 XML 错误（%2:%3）：%4")
                     .arg(relativePath).arg(line).arg(column).arg(parseMessage);
        return {};
    }

    const QString name = relativePath.section(u'/', -1);
    const QJsonObject baseline = m_baseline.value(name).toObject();
    const QRegularExpression perkLevel(QStringLiteral("\\.packmuleCapacityL([1-5])"));
    for (QDomElement operation = document.documentElement().firstChildElement();
         !operation.isNull(); operation = operation.nextSiblingElement()) {
        if (operation.tagName() != QStringLiteral("set"))
            continue;
        const QString path = operation.attribute(QStringLiteral("xpath"));
        QString value = operation.text().trimmed();

        if (name == QStringLiteral("entityclasses.xml")) {
            if (path.contains(QStringLiteral("property[@name='MaxBagSize']"))
                || path.contains(QStringLiteral("passive_effect[@name='BagSize']")))
                value = QString::number(layout.capacity);
            else if (path.contains(QStringLiteral(".carryCapacityBase")))
                value = QString::number(layout.freeSlots);
            else {
                const auto match = perkLevel.match(path);
                if (match.hasMatch())
                    value = QString::number(layout.perk.at(match.captured(1).toInt() - 1));
            }
        } else if (name == QStringLiteral("progression.xml")) {
            if (path.contains(QStringLiteral("perk[@name='perkPackMule']"))) {
                QStringList levels;
                for (int amount : layout.perk)
                    levels.append(QString::number(amount));
                value = levels.join(u',');
            } else {
                value = QString::number(layout.capacity);
            }
        } else if (name == QStringLiteral("buffs.xml")) {
            value = QString::number(layout.capacity
                                    + (path.contains(QStringLiteral("buff[@name='god']")) ? 0 : 5));
        } else if (name == QStringLiteral("items.xml")) {
            value = QString::number(layout.capacity + 5);
        } else if (name == QStringLiteral("loot.xml")) {
            const int lootCols = qBound(8, qRound(layout.cols * .72), 25);
            value = QStringLiteral("%1,%2").arg(lootCols).arg(qMax(12, (layout.capacity + lootCols - 1) / lootCols + 2));
        } else if (name == QStringLiteral("xui.xml")) {
            value = QString::number(layout.stackScale, 'f', 2);
        } else if (name == QStringLiteral("windows.xml")
                   && path.contains(QStringLiteral("window[@name='windowBackpack']"))) {
            if (path.endsWith(QStringLiteral("/@width"))
                && path.contains(QStringLiteral("windowBackpack']/@width")))
                value = QString::number(layout.width);
            else if (path.endsWith(QStringLiteral("/@height"))
                     && path.contains(QStringLiteral("windowBackpack']/@height")))
                value = QString::number(layout.height);
            else if (path.contains(QStringLiteral("rect[@name='content']/@height")))
                value = QString::number(layout.contentHeight);
            else if (path.contains(QStringLiteral("grid[@name='inventory']/@rows")))
                value = QString::number(layout.rows);
            else if (path.contains(QStringLiteral("grid[@name='inventory']/@cols")))
                value = QString::number(layout.cols);
            else if (path.contains(QStringLiteral("grid[@name='inventory']/@cell_width"))
                     || path.contains(QStringLiteral("grid[@name='inventory']/@cell_height"))
                     || path.contains(QStringLiteral("item_stack/@cell_size")))
                value = QString::number(layout.cell);
            else if (baseline.contains(path))
                value = interpolateText(baseline.value(path).toString(), value, layout.interpolation);
        } else if ((name == QStringLiteral("windows.xml") || name == QStringLiteral("templates.xml"))
                   && baseline.contains(path)) {
            value = interpolateText(baseline.value(path).toString(), value, layout.interpolation);
        }

        while (!operation.firstChild().isNull())
            operation.removeChild(operation.firstChild());
        operation.appendChild(document.createTextNode(value));
    }
    return document.toString(2);
}

QString BackpackGenerator::modInfo(const Layout &layout, const QString &folder) const
{
    return QStringLiteral("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                          "<xml>\n"
                          "  <Name value=\"%1\" />\n"
                          "  <DisplayName value=\"%2格大背包%3格负重（V3.3宽版UI）\" />\n"
                          "  <Version value=\"3.3.0.3\" />\n"
                          "  <Description value=\"打破背包模组的频繁更换\" />\n"
                          "  <Author value=\"wangcac制作\" />\n"
                          "  <Website value=\"QQ1843608878\" />\n"
                          "</xml>\n")
        .arg(folder).arg(layout.capacity).arg(layout.freeSlots);
}

QVariantMap BackpackGenerator::saveZip(int capacity, int freeSlots, const QUrl &destination) const
{
    if (capacity < 1 || capacity > 5000 || freeSlots < 0 || freeSlots > capacity)
        return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), QStringLiteral("请输入有效的容量和免负重格数。")}};
    if (!m_loadError.isEmpty())
        return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), m_loadError}};
    if (!destination.isLocalFile())
        return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), QStringLiteral("请选择本地保存位置。")}};

    const Layout data = calculate(capacity, freeSlots);
    const QString folder = QStringLiteral("wangcac-%1BigBackpack%2WB").arg(capacity).arg(freeSlots);
    QList<ZipEntry> entries;
    entries.append({folder + QStringLiteral("/ModInfo.xml"), modInfo(data, folder).toUtf8()});
    for (auto it = m_files.constBegin(); it != m_files.constEnd(); ++it) {
        QString error;
        const QString result = patchXml(it.key(), it.value().toString(), data, &error);
        if (!error.isEmpty())
            return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), error}};
        entries.append({folder + QStringLiteral("/Config/") + it.key(), result.toUtf8()});
    }

    QString target = destination.toLocalFile();
    if (!target.endsWith(QStringLiteral(".zip"), Qt::CaseInsensitive))
        target += QStringLiteral(".zip");
    QSaveFile file(target);
    if (!file.open(QIODevice::WriteOnly))
        return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), file.errorString()}};
    const QByteArray zip = createZip(entries);
    if (file.write(zip) != zip.size() || !file.commit())
        return {{QStringLiteral("ok"), false}, {QStringLiteral("message"), file.errorString()}};
    return {{QStringLiteral("ok"), true}, {QStringLiteral("path"), target}};
}
