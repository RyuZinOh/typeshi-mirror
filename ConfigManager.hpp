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
  Q_PROPERTY(QString username READ username NOTIFY configChanged)
  Q_PROPERTY(QString avatarPath READ avatarPath NOTIFY configChanged)
  Q_PROPERTY(QString currentWordList READ currentWordList NOTIFY configChanged)

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
  QString username() const;
  QString avatarPath() const;
  QString currentWordList() const;

  Q_INVOKABLE void reload();
  Q_INVOKABLE QColor themeColor(const QString &key) const;
  Q_INVOKABLE QStringList availableThemes() const;
  Q_INVOKABLE QVariantMap previewColors(const QString &themeName,
                                        const QString &variant) const;
  Q_INVOKABLE void setTheme(const QString &themeName, const QString &variant);
  Q_INVOKABLE void setCustomTheme(bool enabled);
  Q_INVOKABLE void saveTestDefaults(const QString &mode, int duration,
                                    int wordCount, bool punctuation);
  Q_INVOKABLE void setUsername(const QString &name);
  Q_INVOKABLE QString importAvatar(const QString &sourceFileUrl);
  Q_INVOKABLE void clearAvatar();
  Q_INVOKABLE void setWordList(const QString &name);
  Q_INVOKABLE QStringList availableWordLists() const;

  // custom theme generation
  Q_INVOKABLE bool generateCustomThemeTemplate(bool overwrite = false);

signals:
  void configChanged();

private:
  QVariantMap m_theme;
  QStringList m_words;
  QFileSystemWatcher m_watcher;
  QVariantMap m_general;
  QString m_avatarPath;

  // defaults
  QString m_currentTheme = "midnight_purple";
  QString m_currentVariant = "dark";
  QString m_lastMode = "time";
  int m_lastDuration = 60;
  int m_lastWordCount = 25;
  bool m_lastPunctuation = false;
  QString m_username = "typeShitter";
  QString m_currentWordList = "english";
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
