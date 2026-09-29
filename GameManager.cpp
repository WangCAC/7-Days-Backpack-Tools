#include "GameManager.h"
#include "LocalizationManager.h"

#include <QDir>
#include <QDirIterator>
#include <QDesktopServices>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSettings>
#include <QtConcurrent>

namespace {
constexpr auto gameProgram = "7DaysToDie.exe";

QStringList steamLibraryPaths()
{
    QStringList roots;
#ifdef Q_OS_WIN
    QSettings steamRegistry(QStringLiteral("HKEY_CURRENT_USER\\Software\\Valve\\Steam"),
                            QSettings::NativeFormat);
    const QString steamPath = steamRegistry.value(QStringLiteral("SteamPath")).toString();
    if (!steamPath.isEmpty())
        roots.append(QDir::fromNativeSeparators(steamPath));
#endif
    for (const QFileInfo &drive : QDir::drives()) {
        const QString root = drive.absoluteFilePath();
        roots.append(QDir(root).filePath(QStringLiteral("Program Files (x86)/Steam")));
        roots.append(QDir(root).filePath(QStringLiteral("Program Files/Steam")));
        roots.append(QDir(root).filePath(QStringLiteral("Steam")));
        roots.append(QDir(root).filePath(QStringLiteral("SteamLibrary")));
        roots.append(QDir(root).filePath(QStringLiteral("Games/SteamLibrary")));
    }
    roots.removeDuplicates();

    QStringList libraries = roots;
    const QRegularExpression libraryPath(QStringLiteral("\"path\"\\s*\"([^\"]+)\""),
                                         QRegularExpression::CaseInsensitiveOption);
    for (const QString &root : roots) {
        QFile file(QDir(root).filePath(QStringLiteral("steamapps/libraryfolders.vdf")));
        if (!file.open(QIODevice::ReadOnly))
            continue;
        const QString contents = QString::fromUtf8(file.readAll());
        auto matches = libraryPath.globalMatch(contents);
        while (matches.hasNext()) {
            QString path = matches.next().captured(1);
            path.replace(QStringLiteral("\\\\"), QStringLiteral("\\"));
            libraries.append(QDir::fromNativeSeparators(path));
        }
    }
    libraries.removeDuplicates();
    return libraries;
}
}

GameManager::GameManager(LocalizationManager *localization, QObject *parent)
    : QObject(parent), m_localization(localization)
{
    connect(m_localization, &LocalizationManager::languageChanged, this, [this] {
        if (m_messageKey.isEmpty())
            return;
        m_message = m_localization->text(m_messageKey, m_messageArguments);
        emit messageChanged();
    });
    QSettings settings;
    m_gamePaths = settings.value(QStringLiteral("games/paths")).toStringList();
    m_gamePaths.removeDuplicates();
    const QString previousSelection = settings.value(QStringLiteral("games/selected")).toString();
    for (const QString &stored : m_gamePaths) {
        if (stored.compare(previousSelection, Qt::CaseInsensitive) == 0) {
            m_selectedGamePath = stored;
            break;
        }
    }
    if (m_selectedGamePath.isEmpty() && !m_gamePaths.isEmpty())
        m_selectedGamePath = m_gamePaths.first();

    connect(&m_scanWatcher, &QFutureWatcher<QString>::finished, this, [this] {
        m_scanning = false;
        emit scanningChanged();
        const QString found = m_scanWatcher.result();
        if (found.isEmpty()) {
            setMessage(QStringLiteral("scanNotFound"), {}, true);
            return;
        }
        addGamePath(found, m_selectionRevision == m_scanRevision);
        setMessage(QStringLiteral("gameFound"), {found});
    });
}

QString GameManager::normalizedGamePath(const QString &path)
{
    const QFileInfo file(path);
    if (!file.isFile() || file.fileName().compare(QLatin1String(gameProgram), Qt::CaseInsensitive) != 0)
        return {};
    const QString canonical = file.canonicalFilePath();
    return QDir::cleanPath(canonical.isEmpty() ? file.absoluteFilePath() : canonical);
}

void GameManager::saveSettings() const
{
    QSettings settings;
    settings.setValue(QStringLiteral("games/paths"), m_gamePaths);
    settings.setValue(QStringLiteral("games/selected"), m_selectedGamePath);
    settings.sync();
}

void GameManager::setMessage(const QString &key, const QVariantList &arguments, bool isError)
{
    if (m_messageKey == key && m_messageArguments == arguments && m_messageIsError == isError)
        return;
    m_messageKey = key;
    m_messageArguments = arguments;
    m_messageIsError = isError;
    m_message = m_localization->text(key, arguments);
    emit messageChanged();
}

void GameManager::addGamePath(const QString &path, bool select)
{
    const QString normalized = normalizedGamePath(path);
    if (normalized.isEmpty()) {
        setMessage(QStringLiteral("chooseNamedExe"), {}, true);
        return;
    }
    QString stored = normalized;
    bool exists = false;
    for (const QString &candidate : m_gamePaths) {
        if (candidate.compare(normalized, Qt::CaseInsensitive) == 0) {
            stored = candidate;
            exists = true;
            break;
        }
    }
    if (!exists) {
        m_gamePaths.append(stored);
        emit gamePathsChanged();
    }
    if (select && m_selectedGamePath != stored) {
        m_selectedGamePath = stored;
        ++m_selectionRevision;
        emit selectedGamePathChanged();
    }
    saveSettings();
}

void GameManager::addGame(const QUrl &programUrl)
{
    if (!programUrl.isLocalFile()) {
        setMessage(QStringLiteral("chooseLocalExe"), {}, true);
        return;
    }
    const QString path = normalizedGamePath(programUrl.toLocalFile());
    if (path.isEmpty()) {
        setMessage(QStringLiteral("chooseNamedExe"), {}, true);
        return;
    }
    addGamePath(path, true);
    setMessage(QStringLiteral("gameSelected"), {path});
}

void GameManager::selectGame(const QString &programPath)
{
    for (const QString &stored : m_gamePaths) {
        if (stored.compare(programPath, Qt::CaseInsensitive) != 0)
            continue;
        if (m_selectedGamePath != stored) {
            m_selectedGamePath = stored;
            ++m_selectionRevision;
            emit selectedGamePathChanged();
            saveSettings();
        }
        setMessage(QStringLiteral("gameSelected"), {stored});
        return;
    }
}

QVariantMap GameManager::openModsFolder() const
{
    const QString program = normalizedGamePath(m_selectedGamePath);
    if (program.isEmpty())
        return {{QStringLiteral("ok"), false},
                {QStringLiteral("messageKey"), QStringLiteral("errorChooseGame")}};

    const QString modsPath = QDir(QFileInfo(program).absolutePath()).filePath(QStringLiteral("Mods"));
    if (!QDir().mkpath(modsPath))
        return {{QStringLiteral("ok"), false},
                {QStringLiteral("messageKey"), QStringLiteral("errorCreateMods")},
                {QStringLiteral("messageArgs"), QVariantList{modsPath}}};
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(modsPath)))
        return {{QStringLiteral("ok"), false},
                {QStringLiteral("messageKey"), QStringLiteral("errorOpenMods")},
                {QStringLiteral("messageArgs"), QVariantList{modsPath}}};
    return {{QStringLiteral("ok"), true}, {QStringLiteral("path"), modsPath}};
}

QString GameManager::findFirstGame()
{
    for (const QString &library : steamLibraryPaths()) {
        const QString candidate = QDir(library).filePath(
            QStringLiteral("steamapps/common/7 Days To Die/7DaysToDie.exe"));
        const QString found = normalizedGamePath(candidate);
        if (!found.isEmpty())
            return found;
    }

    for (const QFileInfo &drive : QDir::drives()) {
        QDirIterator files(drive.absoluteFilePath(), QStringList{QStringLiteral("7DaysToDie.exe")},
                           QDir::Files | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
                           QDirIterator::Subdirectories);
        while (files.hasNext()) {
            const QString found = normalizedGamePath(files.next());
            if (!found.isEmpty())
                return found;
        }
    }
    return {};
}

void GameManager::scanGames()
{
    if (m_scanning)
        return;
    m_scanning = true;
    m_scanRevision = m_selectionRevision;
    emit scanningChanged();
    setMessage(QStringLiteral("scanStarted"));
    m_scanWatcher.setFuture(QtConcurrent::run(&GameManager::findFirstGame));
}
