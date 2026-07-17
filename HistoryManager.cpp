#include "./HistoryManager.hpp"
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QtSql/QSqlError>

HistoryManager::HistoryManager(QObject *parent) : QObject(parent) {
  const QString path = dbPath();
  QDir().mkpath(QFileInfo(path).absolutePath());

  m_db = QSqlDatabase::addDatabase("QSQLITE", "history_connection");
  m_db.setDatabaseName(path);

  if (!m_db.open()) {
    qWarning() << "HistoryManager: failed to open db:"
               << m_db.lastError().text();
  } else {
    qDebug() << "HistoryManager: db live at: " << path;
  }
}

HistoryManager::~HistoryManager() {
  if (m_db.isOpen()) {
    qDebug() << "HistoryManager: destroyed!";
    m_db.close();
  }
}

QString HistoryManager::dbPath() const {
  const QString dataDir =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  return dataDir + "/typeshi.db";
}
