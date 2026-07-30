#include "./ConfigManager.hpp"
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#ifndef TYPESHI_VERSION
#define TYPESHI_VERSION "dev"
#endif

namespace {
void loadBundledFonts() {
  QDir fontsDir(
      QStringLiteral(":/qt/qml/typeShitter/application/assets/fonts"));
  const QStringList folders =
      fontsDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

  for (const QString &folder : folders) {
    QDir familyDir(fontsDir.filePath(folder));
    const QStringList files = familyDir.entryList({"*.ttf"}, QDir::Files);

    qDebug() << "fonts: " << files;
    for (const QString &file : files) {
      const int id =
          QFontDatabase::addApplicationFont(familyDir.filePath(file));
      if (id == -1) {
        qWarning() << "failed to Load the fonts: " << familyDir.filePath(file);
        continue;
      }
      const QStringList families = QFontDatabase::applicationFontFamilies(id);
      if (!families.isEmpty()) {
        ConfigManager::registerFontFamily(families.first());
      }
    }
  }
}
} // namespace

int main(int argc, char *argv[]) {

  QGuiApplication app(argc, argv);

  app.setApplicationName("typeShi");
  app.setApplicationVersion(TYPESHI_VERSION);
  app.setWindowIcon(
      QIcon(":/qt/qml/typeShitter/application/assets/typeShi.svg"));
  loadBundledFonts();
  QCommandLineParser parser;
  parser.setApplicationDescription("typeshi - a typing application");
  parser.addHelpOption();
  parser.addVersionOption();
  QCommandLineOption genThemeOption("generate-custom-theme",
                                    "Writes  a starter theme to config.ini for "
                                    "user to have one template to edit...");
  parser.addOption(genThemeOption);

  QCommandLineOption forceOption(
      {"f", "force"},
      "Overwrites an existing config.ini when used generate-custom-theme");
  parser.addOption(forceOption);
  parser.process(app);

  if (parser.isSet(genThemeOption)) {
    ConfigManager con;
    const bool ok = con.generateCustomThemeTemplate(parser.isSet(forceOption));
    return ok ? 0 : 1;
  }

  QQmlApplicationEngine engine;
  engine.loadFromModule("typeShitter", "Main");

  return app.exec();
}
