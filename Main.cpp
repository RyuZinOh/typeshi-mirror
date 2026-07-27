#include "./ConfigManager.hpp"
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#ifndef TYPESHI_VERSION
#define TYPESHI_VERSION "dev"
#endif

int main(int argc, char *argv[]) {

  QGuiApplication app(argc, argv);

  app.setApplicationName("typeShi");
  app.setApplicationVersion(TYPESHI_VERSION);
  app.setWindowIcon(
      QIcon(":/qt/qml/typeShitter/application/assets/typeShi.svg"));
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
