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
  Q_PROPERTY(QVariantMap theme READ theme NOTIFY configChanged)
  Q_PROPERTY(QStringList words READ words NOTIFY configChanged)

public:
  explicit ConfigManager(QObject *parent = nullptr);

  QVariantMap theme() const;
  QStringList words() const;

  Q_INVOKABLE void reload();
  Q_INVOKABLE QColor themeColor(const QString &key) const;

signals:
  void configChanged();

private:
  QVariantMap m_theme;
  QStringList m_words;
  QFileSystemWatcher m_watcher;

  QString configDir() const;
  QString configPath() const;
  void load();
  void loadWords();
  void parseIniFile(const QString &path, QVariantMap &themeOut) const;
};
