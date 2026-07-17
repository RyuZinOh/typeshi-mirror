#include "./ConfigManager.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>

ConfigManager::ConfigManager(QObject *parent) : QObject(parent) {
  load();

  m_watcher.addPath(configPath());
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this](const QString &path) {
            load();
            if (!m_watcher.files().contains(path)) {
              m_watcher.addPath(path);
            }
          });
}

QString ConfigManager::configDir() const {
  return QDir::homePath() + "/.config/typeShi";
}

QString ConfigManager::configPath() const {
  return configDir() + "/config.ini";
}

void ConfigManager::parseIniFile(const QString &path,
                                 QVariantMap &themeOut) const {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return;
  }

  QTextStream in(&file);
  QString currentSection;

  while (!in.atEnd()) {
    const QString line = in.readLine().trimmed();
    if (line.isEmpty() || line.startsWith('#') || line.startsWith(';')) {
      continue;
    }

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.mid(1, line.length() - 2).trimmed().toLower();
      continue;
    }
    const int eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }

    const QString key = line.left(eq).trimmed();
    QString value = line.mid(eq + 1).trimmed();

    if (value.length() >= 2 && value.front() == value.back() &&
        (value.front() == '"' || value.front() == '\'')) {
      value = value.mid(1, value.length() - 2);
    }

    if (currentSection == "theme") {
      themeOut[key] = value;
    }
  }
}

void ConfigManager::loadWords() {
  m_words.clear();

  QFile file(
      QStringLiteral(":/qt/qml/typeShitter/application/assets/config.ini"));
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    m_words = {"the", "be", "of", "and", "a", "to", "in"};
    return;
  }

  QTextStream in(&file);
  QString currentSection;

  while (!in.atEnd()) {
    const QString line = in.readLine().trimmed();

    if (line.isEmpty() || line.startsWith('#') || line.startsWith(';')) {
      continue;
    }

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.mid(1, line.length() - 2).trimmed().toLower();
      continue;
    }

    const int eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }

    const QString key = line.left(eq).trimmed();
    const QString value = line.mid(eq + 1).trimmed();

    if (currentSection == "english" &&
        key.compare("list", Qt::CaseInsensitive) == 0) {
      const QStringList parts = value.split(',', Qt::SkipEmptyParts);
      for (const QString &part : parts) {
        m_words.append(part.trimmed().toLower());
      }
    }
  }

  if (m_words.isEmpty()) {
    return;
  }
}

void ConfigManager::load() {
  m_theme.clear();

  parseIniFile(configPath(), m_theme);
  loadWords();

  emit configChanged();
}

void ConfigManager::reload() { load(); }

QVariantMap ConfigManager::theme() const { return m_theme; }
QStringList ConfigManager::words() const { return m_words; }
