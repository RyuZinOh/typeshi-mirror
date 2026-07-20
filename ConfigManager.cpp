#include "./ConfigManager.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>

ConfigManager::ConfigManager(QObject *parent) : QObject(parent) {
  load();

  m_watcher.addPath(configPath());
  QDir().mkpath(stateDir());
  if (QFile::exists(statePath())) {
    m_watcher.addPath(statePath());
  }
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this](const QString &path) {
            load();
            if (!m_watcher.files().contains(path) && QFile::exists(path)) {
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

QString ConfigManager::stateDir() const {
  const QString xdgState = qEnvironmentVariable("XDG_STATE_HOME");
  if (!xdgState.isEmpty()) {
    return xdgState + "/typeShi";
  }
  return QDir::homePath() + "/.local/state/typeShi";
}

QString ConfigManager::statePath() const { return stateDir() + "/state.ini"; }

void ConfigManager::parseSection(const QString &path, const QString &section,
                                 QVariantMap &out) const {
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

    if (currentSection == section) {
      out[key] = value;
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
  QVariantMap general;

  parseSection(statePath(), "general", general);

  m_currentTheme = general.value("theme", "midnight_purple").toString();
  m_currentVariant = general.value("variant", "dark").toString();

  if (m_currentTheme.compare("custom", Qt::CaseInsensitive) == 0) {
    parseSection(configPath(), "theme", m_theme);
  } else {
    const QString bundledPath =
        QStringLiteral(
            ":/qt/qml/typeShitter/application/assets/themes/%1/%2.ini")
            .arg(m_currentTheme, m_currentVariant);
    parseSection(bundledPath, "theme", m_theme);

    if (m_theme.isEmpty()) {
      qWarning() << m_currentTheme << "x" << m_currentVariant
                 << "not found, falling back to defaults..";
      m_currentTheme = "midnight_purple";
      m_currentVariant = "dark";
      parseSection(QStringLiteral(":/qt/qml/typeShitter/application/assets/"
                                  "themes/midnight_purple/dark.ini"),
                   "theme", m_theme);
    }
  }

  loadWords();

  emit configChanged();
}

void ConfigManager::reload() { load(); }

void ConfigManager::writeState(const QString &themeName,
                               const QString &variant) {
  QDir().mkpath(stateDir());
  QFile file(statePath());

  if (!file.open(QIODevice::WriteOnly | QIODevice::Text |
                 QIODevice::Truncate)) {
    qWarning() << "ConfigManager:: failed to write" << statePath();
    return;
  }
  QTextStream stream(&file);
  stream << "[general]\n";
  stream << "theme=" << themeName << "\n";
  if (!variant.isEmpty()) {
    stream << "variant=" << variant << "\n";
  }
  file.close();

  if (!m_watcher.files().contains(statePath())) {
    m_watcher.addPath(statePath());
  }
  load();
}

void ConfigManager::setTheme(const QString &themeName, const QString &variant) {
  writeState(themeName, variant.isEmpty() ? m_currentVariant : variant);
}

void ConfigManager::setCustomTheme(bool enabled) {
  if (enabled) {
    writeState("custom", QString());
  } else {
    writeState(m_currentTheme == "custom" ? "midnight_purple" : m_currentTheme,
               m_currentVariant.isEmpty() ? "dark" : m_currentVariant);
  }
}

QVariantMap ConfigManager::theme() const { return m_theme; }
QStringList ConfigManager::words() const { return m_words; }
QString ConfigManager::currentTheme() const { return m_currentTheme; }
QString ConfigManager::currentVariant() const { return m_currentVariant; }

QStringList ConfigManager::availableThemes() const {
  QDir dir(QStringLiteral(":/qt/qml/typeShitter/application/assets/"
                          "themes"));
  return dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
}

QColor ConfigManager::themeColor(const QString &key) const {
  const QVariant value = m_theme.value(key);
  const QString str = value.toString();

  if (!value.isValid() || str.isEmpty() || str.contains(QStringLiteral("{{"))) {
    qWarning() << "Theme: bad/missing matugen color for key:" << key
               << "value:" << str;
    return QColor(Qt::red);
  }

  const QColor color(str);
  if (!color.isValid()) {
    qWarning() << "Theme: unparseable color for key:" << key << "value:" << str;
    return QColor(Qt::red);
  }
  return color;
}
