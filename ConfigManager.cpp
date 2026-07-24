#include "./ConfigManager.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QUrl>

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
QVariantMap ConfigManager::previewColors(const QString &themeName,
                                         const QString &variant) const {
  QVariantMap out;
  const QString path =
      QStringLiteral(":/qt/qml/typeShitter/application/assets/themes/%1/%2.ini")
          .arg(themeName, variant);
  parseSection(path, "theme", out);
  return out;
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

    if (currentSection == m_currentWordList.toLower() &&
        key.compare("list", Qt::CaseInsensitive) == 0) {
      const QStringList parts = value.split(',', Qt::SkipEmptyParts);
      for (const QString &part : parts) {
        m_words.append(part.trimmed().toLower());
      }
    }
  }

  if (m_words.isEmpty()) {
    if (m_currentWordList != "english") {
      qWarning() << "ConfigManager: word list" << m_currentWordList
                 << "empty/missing, falling back to english";
      m_currentWordList = "english";
      loadWords();
    }
    return;
  }
}

void ConfigManager::load() {
  m_theme.clear();
  m_general.clear();
  parseSection(statePath(), "general", m_general);

  m_currentTheme = m_general.value("theme", "midnight_purple").toString();
  m_currentVariant = m_general.value("variant", "dark").toString();
  m_lastMode = m_general.value("lastMode", "time").toString();
  m_lastDuration = m_general.value("lastDuration", "60").toInt();
  m_lastWordCount = m_general.value("lastWordCount", "25").toInt();
  m_lastPunctuation = m_general.value("lastPunctuation", "0").toString() == "1";
  m_currentWordList = m_general.value("wordList", "english").toString();

  m_username = m_general.value("username", "typeshitter").toString();
  m_avatarPath = m_general.value("avatarPath", "").toString();

  if (!m_avatarPath.isEmpty() && !QFile::exists(m_avatarPath)) {
    m_avatarPath.clear();
  }

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
void ConfigManager::setUsername(const QString &name) {
  const QString trimmed = name.trimmed();
  if (trimmed.isEmpty() || trimmed == m_username) {
    return;
  }
  m_general["username"] = trimmed.left(24);
  m_username = trimmed.left(24);
  writeGeneral();
  emit configChanged();
}

QString ConfigManager::importAvatar(const QString &sourceFileUrl) {
  QUrl url(sourceFileUrl);
  const QString sourcePath =
      url.isLocalFile() ? url.toLocalFile() : sourceFileUrl;

  QFileInfo info(sourcePath);
  if (!info.exists() || !info.isFile()) {
    qWarning() << "ConfigManager: avatar source doesn't exist:" << sourcePath;
    return QString();
  }

  const QStringList allowed = {"png", "jpg", "jpeg", "webp"};
  if (!allowed.contains(info.suffix().toLower())) {
    qWarning() << "ConfigManager: unsupported avatar format:" << info.suffix();
    return QString();
  }

  const QString avatarDir = stateDir() + "/avatar";
  // const QString destPath = avatarDir + "/profile." + info.suffix().toLower();

  QDir(avatarDir).removeRecursively();
  QDir().mkpath(avatarDir);

  const qint64 stamp = QDateTime::currentMSecsSinceEpoch();
  const QString destPath =
      avatarDir +
      QString("/profile_%1.%2").arg(stamp).arg(info.suffix().toLower());

  if (!QFile::copy(sourcePath, destPath)) {
    qWarning() << "ConfigManager: failed to copy avatar to" << destPath;
    return QString();
  }

  m_general["avatarPath"] = destPath;
  m_avatarPath = destPath;
  writeGeneral();
  emit configChanged();
  return destPath;
}

void ConfigManager::clearAvatar() {
  if (m_avatarPath.isEmpty()) {
    return;
  }
  QFile::remove(m_avatarPath);
  m_general["avatarPath"] = "";
  m_avatarPath.clear();
  writeGeneral();
  emit configChanged();
}
void ConfigManager::reload() { load(); }

void ConfigManager::writeGeneral() {
  QDir().mkpath(stateDir());
  QFile file(statePath());

  if (!file.open(QIODevice::WriteOnly | QIODevice::Text |
                 QIODevice::Truncate)) {
    qWarning() << "ConfigManager:: failed to write" << statePath();
    return;
  }
  QTextStream stream(&file);
  stream << "[general]\n";
  for (auto it = m_general.constBegin(); it != m_general.constEnd(); ++it) {
    stream << it.key() << "=" << it.value().toString() << "\n";
  }
  file.close();

  if (!m_watcher.files().contains(statePath())) {
    m_watcher.addPath(statePath());
  }
}

void ConfigManager::setTheme(const QString &themeName, const QString &variant) {
  m_general["theme"] = themeName;
  m_general["variant"] = variant.isEmpty() ? m_currentVariant : variant;
  writeGeneral();
  load();
}

void ConfigManager::setCustomTheme(bool enabled) {
  if (enabled) {
    m_general["theme"] = "custom";
  } else {
    m_general["theme"] =
        m_currentTheme == "custom" ? "midnight_purple" : m_currentTheme;
    m_general["variant"] =
        m_currentVariant.isEmpty() ? "dark" : m_currentVariant;
  }
  writeGeneral();
  load();
}

void ConfigManager::setWordList(const QString &name) {
  if (name == m_currentWordList) {
    return;
  }
  m_general["wordList"] = name;
  writeGeneral();
  load();
}

QStringList ConfigManager::availableWordLists() const {
  QStringList result;
  QFile file(
      QStringLiteral(":/qt/qml/typeShitter/application/assets/config.ini"));
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return result;
  }
  QTextStream in(&file);
  while (!in.atEnd()) {
    const QString line = in.readLine().trimmed();
    if (line.startsWith('[') && line.endsWith(']')) {
      result.append(line.mid(1, line.length() - 2).trimmed());
    }
  }
  return result;
}
void ConfigManager::saveTestDefaults(const QString &mode, int duration,
                                     int wordCount, bool punctuation) {
  m_general["lastMode"] = mode;
  m_general["lastDuration"] = duration;
  m_general["lastWordCount"] = wordCount;
  m_general["lastPunctuation"] = punctuation ? "1" : "0";
  m_lastMode = mode;
  m_lastDuration = duration;
  m_lastWordCount = wordCount;
  m_lastPunctuation = punctuation;
  writeGeneral();
  emit configChanged();
}
// getters
QString ConfigManager::currentWordList() const { return m_currentWordList; }
QVariantMap ConfigManager::theme() const { return m_theme; }
QStringList ConfigManager::words() const { return m_words; }
QString ConfigManager::currentTheme() const { return m_currentTheme; }
QString ConfigManager::currentVariant() const { return m_currentVariant; }
QString ConfigManager::lastMode() const { return m_lastMode; }
int ConfigManager::lastDuration() const { return m_lastDuration; }
int ConfigManager::lastWordCount() const { return m_lastWordCount; }
bool ConfigManager::lastPunctuation() const { return m_lastPunctuation; }
QString ConfigManager::username() const { return m_username; }
QString ConfigManager::avatarPath() const { return m_avatarPath; }
// end of getters

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
