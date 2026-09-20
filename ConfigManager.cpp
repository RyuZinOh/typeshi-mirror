#include "./ConfigManager.hpp"
#include <QDir>
#include <QFile>
#include <QStandardPaths>
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
  return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
}

QString ConfigManager::configPath() const {
  return configDir() + "/config.ini";
}

QString ConfigManager::stateDir() const {
  return QStandardPaths::writableLocation(
             QStandardPaths::AppLocalDataLocation) +
         "/state";
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

void ConfigManager::setBorderProgressEnabled(bool enabled) {
  if (enabled == m_borderProgressEnabled) {
    return;
  }
  m_borderProgressEnabled = enabled;
  m_general["borderProgressEnabled"] = enabled ? "1" : "0";
  writeGeneral();
  emit configChanged();
}

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

// font stuff
void ConfigManager::setFont(const QString &name) {
  if (name == m_currentFont) {
    return;
  }
  m_general["font"] = name;
  m_currentFont = name;
  writeGeneral();
  emit configChanged();
}

QStringList ConfigManager::s_availableFonts;
void ConfigManager::registerFontFamily(const QString &family) {
  if (!s_availableFonts.contains(family)) {
    s_availableFonts.append(family);
  }
}

void ConfigManager::setFontSize(int size) {
  size = qBound(20, size, 64);
  if (size == m_fontSize) {
    return;
  }
  m_general["fontSize"] = size;
  m_fontSize = size;
  writeGeneral();
  emit configChanged();
}
QStringList ConfigManager::availableFonts() const { return s_availableFonts; }
// end of font stuff
void ConfigManager::load() {
  m_theme.clear();
  m_general.clear();
  parseSection(statePath(), "general", m_general);

  m_currentTheme = m_general.value("theme", "midnight_purple").toString();
  m_currentFont = m_general.value("font", "Roboto").toString();
  if (!s_availableFonts.isEmpty() &&
      !s_availableFonts.contains(m_currentFont)) {
    qWarning() << "ConfigManager: saved font" << m_currentFont
               << "not registered, falling back to Roboto";
    m_currentFont = "Roboto";
    m_general["font"] = "Roboto";
    writeGeneral();
  }
  m_fontSize = m_general.value("fontSize", "36").toInt();
  m_borderProgressEnabled =
      m_general.value("borderProgressEnabled", "1").toString() == "1";
  m_currentVariant = m_general.value("variant", "dark").toString();
  m_lastMode = m_general.value("lastMode", "time").toString();
  m_lastDuration = m_general.value("lastDuration", "60").toInt();
  m_lastWordCount = m_general.value("lastWordCount", "25").toInt();
  m_lastPunctuation = m_general.value("lastPunctuation", "0").toString() == "1";
  m_tapeModeEnabled = m_general.value("tapeModeEnabled", "0").toString() == "1";
  m_precisionModeEnabled =
      m_general.value("precisionModeEnabled", "0").toString() == "1";
  m_keyboardVizModeenabled =
      m_general.value("keyboardVizModeEnabled", "0").toString() == "1";
  m_watcherEnabled = m_general.value("watcherEnabled", "1").toString() == "1";
  m_currentWordList = m_general.value("wordList", "english").toString();

  m_username = m_general.value("username", "typeshitter").toString();
  m_avatarPath = m_general.value("avatarPath", "").toString();

  if (!m_avatarPath.isEmpty() && !QFile::exists(m_avatarPath)) {
    m_avatarPath.clear();
  }

  if (m_currentTheme.compare("custom", Qt::CaseInsensitive) == 0) {
    parseSection(configPath(), "theme", m_theme);
    if (m_theme.isEmpty()) {
      qWarning() << "custom theme file config.ini is empty, defaulting...";
      m_general["theme"] = "midnight_purple";
      m_general["variant"] = "dark";
      writeGeneral();
      m_currentTheme = "midnight_purple";
      m_currentVariant = "dark";
      parseSection(QStringLiteral(":/qt/qml/typeShitter/application/assets/"
                                  "themes/midnight_purple/dark.ini"),
                   "theme", m_theme);
    }
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
bool ConfigManager::borderProgressEnabled() const {
  return m_borderProgressEnabled;
}
QString ConfigManager::currentWordList() const { return m_currentWordList; }
QVariantMap ConfigManager::theme() const { return m_theme; }
QStringList ConfigManager::words() const { return m_words; }
QString ConfigManager::currentTheme() const { return m_currentTheme; }
QString ConfigManager::currentVariant() const { return m_currentVariant; }
QString ConfigManager::lastMode() const { return m_lastMode; }
int ConfigManager::lastDuration() const { return m_lastDuration; }
int ConfigManager::lastWordCount() const { return m_lastWordCount; }
int ConfigManager::fontSize() const { return m_fontSize; }
bool ConfigManager::lastPunctuation() const { return m_lastPunctuation; }
QString ConfigManager::username() const { return m_username; }
QString ConfigManager::avatarPath() const { return m_avatarPath; }
QString ConfigManager::currentFont() const { return m_currentFont; }
bool ConfigManager::tapeModeEnabled() const { return m_tapeModeEnabled; }
bool ConfigManager::precisionModeEnabled() const {
  return m_precisionModeEnabled;
}
bool ConfigManager::keyboardVizModeEnabled() const {
  return m_keyboardVizModeenabled;
}
bool ConfigManager::watcherEnabled() const { return m_watcherEnabled; }
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

void ConfigManager::setTapeModeEnabled(bool enabled) {
  if (enabled == m_tapeModeEnabled) {
    return;
  }
  m_tapeModeEnabled = enabled;
  m_general["tapeModeEnabled"] = enabled ? "1" : "0";
  writeGeneral();
  emit configChanged();
}

void ConfigManager::setWatcherEnabled(bool enabled) {
  if (enabled == m_watcherEnabled) {
    return;
  }
  m_watcherEnabled = enabled;
  m_general["watcherEnabled"] = enabled ? "1" : "0";
  writeGeneral();
  emit configChanged();
}

void ConfigManager::setPrecisionModeEnabled(bool enabled) {
  if (enabled == m_precisionModeEnabled) {
    return;
  }
  m_precisionModeEnabled = enabled;
  m_general["precisionModeEnabled"] = enabled ? "1" : "0";
  writeGeneral();
  emit configChanged();
}

void ConfigManager::setKeyboardVizModeEnabled(bool enabled) {
  if (enabled == m_keyboardVizModeenabled) {
    return;
  }
  m_keyboardVizModeenabled = enabled;
  m_general["keyboardVizModeEnabled"] = enabled ? "1" : "0";
  writeGeneral();
  emit configChanged();
}

// custom theme generation
bool ConfigManager::generateCustomThemeTemplate(bool overwrite) {
  const QString path = configPath();

  if (QFile::exists(path) && !overwrite) {
    qWarning() << "Custom Theme already exists at" << path
               << "\n use --force to overwrite";
    return false;
  }
  QDir().mkpath(configDir());
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Text |
                 QIODevice::Truncate)) {
    qWarning() << "Failed to write custom theme at" << path;
    return false;
  }

  QTextStream out(&file);
  out << R"([theme]
background=#18120c
surface=#18120c
surface_bright=#403831
surface_container=#251e18
surface_container_low=#211a14
surface_container_high=#302922
surface_container_highest=#3b332c
surface_dim=#18120c
primary=#ffb86b
primary_container=#c7812d
primary_fixed=#ffdcbc
primary_fixed_dim=#ffb86b
secondary=#e9bf94
secondary_container=#5e4120
secondary_fixed=#ffdcbc
secondary_fixed_dim=#e9bf94
tertiary=#c1ce67
tertiary_container=#8b9837
tertiary_fixed=#ddeb80
tertiary_fixed_dim=#c1ce67
error=#ffb4ab
error_container=#93000a
on_background=#eee0d6
on_surface=#eee0d6
on_surface_variant=#d7c3b2
on_primary=#492900
on_primary_container=#000000
on_primary_fixed=#2c1700
on_primary_fixed_variant=#683d00
on_secondary=#452b0c
on_secondary_container=#ffd9b6
on_secondary_fixed=#2c1700
on_secondary_fixed_variant=#5e4120
on_tertiary=#2d3400
on_tertiary_container=#000000
on_tertiary_fixed=#1a1e00
on_tertiary_fixed_variant=#434b00
on_error=#690005
on_error_container=#ffdad6
outline=#9f8e7e
outline_variant=#524437
inverse_surface=#eee0d6
inverse_on_surface=#372f28
inverse_primary=#895100
scrim=#000000
shadow=#000000
)";
  file.close();
  qDebug() << "Successfully added custom theme template to " << path;
  return true;
}

// end of custom theme generation
