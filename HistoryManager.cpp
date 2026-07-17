#include "./HistoryManager.hpp"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQuery>

HistoryManager::HistoryManager(QObject *parent) : QObject(parent) {
  const QString path = dbPath();
  QDir().mkpath(QFileInfo(path).absolutePath());

  m_db = QSqlDatabase::addDatabase("QSQLITE", "history_connection");
  m_db.setDatabaseName(path);

  if (!m_db.open()) {
    qWarning() << "HistoryManager: failed to open db:"
               << m_db.lastError().text();
    return;
  }
  qDebug() << "HistoryManager: db live at: " << path;
  ensureSchema();
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

void HistoryManager::ensureSchema() {
  QSqlQuery q(m_db);

  const bool ok = q.exec(R"(
  create table if not exists results (
  id integer primary key autoincrement,
  timestamp integer not null,
  date text not null,
  wpm real not null,
  raw_wpm real not null,
  accuracy real not null,
  consistency real not null,
  duration_seconds integer not null,
  correct_count integer not null,
  incorrect_count integer not null,
  extra_count integer not null,
  missed_count integer not null
  )
  )");
  if (!ok) {
    qWarning() << "HistoryManager: failed to create table: "
               << q.lastError().text();
  }
}

void HistoryManager::recordResult(double wpm, double rawWpm, double accuracy,
                                  double consistency, int durationSeconds,
                                  int correctCount, int incorrectCount,
                                  int extraCount, int missedCount) {
  if (!m_db.isOpen()) {
    qWarning() << "HistoryManager: db not open, can't record result";
    return;
  }

  const QDateTime now = QDateTime::currentDateTime();
  QSqlQuery q(m_db);
  q.prepare(R"(
  insert into results (timestamp, date, wpm, raw_wpm, accuracy, consistency, duration_seconds, correct_count, incorrect_count, extra_count, missed_count) values (?,?,?,?,?,?,?,?,?,?,?)
  )");
  q.addBindValue(now.toSecsSinceEpoch());
  q.addBindValue(now.toString("yyyy-MM-dd"));
  q.addBindValue(wpm);
  q.addBindValue(rawWpm);
  q.addBindValue(accuracy);
  q.addBindValue(consistency);
  q.addBindValue(durationSeconds);
  q.addBindValue(correctCount);
  q.addBindValue(incorrectCount);
  q.addBindValue(extraCount);
  q.addBindValue(missedCount);

  if (!q.exec()) {
    qWarning() << "HistoryManager: insert failed: " << q.lastError().text();
  }
}
