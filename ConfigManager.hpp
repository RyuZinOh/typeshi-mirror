#pragma once
#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QStringList>
#include <QVariantMap>
#include <QtQmlIntegration/qqmlintegration.h>

class ConfigManager : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Config)
  QML_SINGLETON
  Q_PROPERTY(QString currentTheme READ currentTheme NOTIFY configChanged)
  Q_PROPERTY(QString currentVariant READ currentVariant NOTIFY configChanged)
  Q_PROPERTY(QVariantMap theme READ theme NOTIFY configChanged)
  Q_PROPERTY(QStringList words READ words NOTIFY configChanged)

public:
  explicit ConfigManager(QObject *parent = nullptr);

  QVariantMap theme() const;
  QStringList words() const;
  QString currentTheme() const;
  QString currentVariant() const;

  Q_INVOKABLE void reload();
  Q_INVOKABLE QColor themeColor(const QString &key) const;
  Q_INVOKABLE QStringList availableThemes() const;
  Q_INVOKABLE void setTheme(const QString &themeName, const QString &variant);
  Q_INVOKABLE void setCustomTheme(bool enabled);

signals:
  void configChanged();

private:
  QVariantMap m_theme;
  QStringList m_words;
  QFileSystemWatcher m_watcher;

  // defaults
  QString m_currentTheme = "midnight_purple";
  QString m_currentVariant = "dark";
  // end of defaults

  QString configDir() const;
  QString configPath() const;
  QString stateDir() const;
  QString statePath() const;

  void load();
  void loadWords();
  void writeState(const QString &themeName, const QString &variant);
  void parseSection(const QString &path, const QString &section,
                    QVariantMap &out) const;
};
