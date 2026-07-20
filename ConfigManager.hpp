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
  Q_PROPERTY(QString lastMode READ lastMode NOTIFY configChanged)
  Q_PROPERTY(int lastDuration READ lastDuration NOTIFY configChanged)
  Q_PROPERTY(int lastWordCount READ lastWordCount NOTIFY configChanged)
  Q_PROPERTY(bool lastPunctuation READ lastPunctuation NOTIFY configChanged)

public:
  explicit ConfigManager(QObject *parent = nullptr);

  QVariantMap theme() const;
  QStringList words() const;
  QString currentTheme() const;
  QString currentVariant() const;
  QString lastMode() const;
  int lastDuration() const;
  int lastWordCount() const;
  bool lastPunctuation() const;

  Q_INVOKABLE void reload();
  Q_INVOKABLE QColor themeColor(const QString &key) const;
  Q_INVOKABLE QStringList availableThemes() const;
  Q_INVOKABLE QVariantMap previewColors(const QString &themeName,
                                        const QString &variant) const;
  Q_INVOKABLE void setTheme(const QString &themeName, const QString &variant);
  Q_INVOKABLE void setCustomTheme(bool enabled);
  Q_INVOKABLE void saveTestDefaults(const QString &mode, int duration,
                                    int wordCount, bool punctuation);

signals:
  void configChanged();

private:
  QVariantMap m_theme;
  QStringList m_words;
  QFileSystemWatcher m_watcher;
  QVariantMap m_general;

  // defaults
  QString m_currentTheme = "midnight_purple";
  QString m_currentVariant = "dark";
  QString m_lastMode = "time";
  int m_lastDuration = 60;
  int m_lastWordCount = 25;
  bool m_lastPunctuation = false;
  // end of defaults

  QString configDir() const;
  QString configPath() const;
  QString stateDir() const;
  QString statePath() const;

  void load();
  void loadWords();
  void writeGeneral();
  void parseSection(const QString &path, const QString &section,
                    QVariantMap &out) const;
};
