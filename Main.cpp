#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {

  QGuiApplication app(argc, argv);

  app.setApplicationName("typeShi");
  app.setWindowIcon(
      QIcon(":/qt/qml/typeShitter/application/assets/typeShi.svg"));
  QQmlApplicationEngine engine;
  engine.loadFromModule("typeShitter", "Main");

  return app.exec();
}
