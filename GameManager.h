#pragma once

#include <QFutureWatcher>
#include <QObject>
#include <QStringList>
#include <QUrl>
#include <QVariantMap>

class LocalizationManager;

class GameManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList gamePaths READ gamePaths NOTIFY gamePathsChanged)
    Q_PROPERTY(QString selectedGamePath READ selectedGamePath NOTIFY selectedGamePathChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QString message READ message NOTIFY messageChanged)
    Q_PROPERTY(bool messageIsError READ messageIsError NOTIFY messageChanged)

public:
    explicit GameManager(LocalizationManager *localization, QObject *parent = nullptr);

    QStringList gamePaths() const { return m_gamePaths; }
    QString selectedGamePath() const { return m_selectedGamePath; }
    bool scanning() const { return m_scanning; }
    QString message() const { return m_message; }
    bool messageIsError() const { return m_messageIsError; }

    Q_INVOKABLE void scanGames();
    Q_INVOKABLE void addGame(const QUrl &programUrl);
    Q_INVOKABLE void selectGame(const QString &programPath);
    Q_INVOKABLE QVariantMap openModsFolder() const;

signals:
    void gamePathsChanged();
    void selectedGamePathChanged();
    void scanningChanged();
    void messageChanged();

private:
    static QString findFirstGame();
    static QString normalizedGamePath(const QString &path);
    void addGamePath(const QString &path, bool select);
    void setMessage(const QString &key, const QVariantList &arguments = {}, bool isError = false);
    void saveSettings() const;

    QStringList m_gamePaths;
    QString m_selectedGamePath;
    QString m_message;
    QString m_messageKey;
    QVariantList m_messageArguments;
    bool m_messageIsError = false;
    LocalizationManager *m_localization;
    bool m_scanning = false;
    quint64 m_selectionRevision = 0;
    quint64 m_scanRevision = 0;
    QFutureWatcher<QString> m_scanWatcher;
};
