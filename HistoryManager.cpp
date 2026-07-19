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
  word_count integer not null default 0,
  correct_count integer not null,
  incorrect_count integer not null,
  extra_count integer not null,
  missed_count integer not null,
  mode text not null default 'english',
  punctuation_enabled integer not null default 0
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
                                  int extraCount, int missedCount,
                                  const QString &mode, bool punctuationEnabled,
                                  int wordCount) {
  if (!m_db.isOpen()) {
    qWarning() << "HistoryManager: db not open, can't record result";
    return;
  }

  const QDateTime now = QDateTime::currentDateTime();
  QSqlQuery q(m_db);
  q.prepare(R"(
  insert into results (timestamp, date, wpm, raw_wpm, accuracy, consistency, duration_seconds,word_count,correct_count, incorrect_count, extra_count, missed_count, mode, punctuation_enabled) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
  )");
  q.addBindValue(now.toSecsSinceEpoch());
  q.addBindValue(now.toString("yyyy-MM-dd"));
  q.addBindValue(wpm);
  q.addBindValue(rawWpm);
  q.addBindValue(accuracy);
  q.addBindValue(consistency);
  q.addBindValue(durationSeconds);
  q.addBindValue(wordCount);
  q.addBindValue(correctCount);
  q.addBindValue(incorrectCount);
  q.addBindValue(extraCount);
  q.addBindValue(missedCount);
  q.addBindValue(mode);
  q.addBindValue(punctuationEnabled ? 1 : 0);

  if (!q.exec()) {
    qWarning() << "HistoryManager: insert failed: " << q.lastError().text();
  }
  emit historyChanged();
}

double HistoryManager::bestWpm() const {
  if (!m_db.isOpen()) {
    return 0.0;
  }
  QSqlQuery q(m_db);
  q.exec("select max(wpm) from results");
  return q.next() ? q.value(0).toDouble() : 0.0;
}

double HistoryManager::bestWpmFor(const QString &mode, int durationSeconds,
                                  int punctuationEnabled, int wordCount) const {
  if (!m_db.isOpen()) {
    return 0.0;
  }

  QSqlQuery q(m_db);
  QString sql = "select max(wpm) from results where 1=1";

  if (!mode.isEmpty()) {
    sql += " and mode = ?";
  }
  if (durationSeconds > 0) {
    sql += " and duration_seconds = ?";
  }
  if (punctuationEnabled >= 0) {
    sql += " and punctuation_enabled = ?";
  }
  if (wordCount > 0) {
    sql += " and word_count = ?";
  }

  q.prepare(sql);
  if (!mode.isEmpty()) {
    q.addBindValue(mode);
  }
  if (durationSeconds > 0) {
    q.addBindValue(durationSeconds);
  }
  if (punctuationEnabled >= 0) {
    q.addBindValue(punctuationEnabled);
  }
  if (wordCount > 0) {
    q.addBindValue(wordCount);
  }

  q.exec();
  return q.next() ? q.value(0).toDouble() : 0.0;
}

double HistoryManager::bestWpmForWords(int wordCount,
                                       int punctuationEnabled) const {
  return bestWpmFor("words", 0, punctuationEnabled, wordCount);
}

int HistoryManager::testsToday() const {
  if (!m_db.isOpen()) {
    return 0;
  }
  QSqlQuery q(m_db);
  q.exec("select count(*) from results where date  = ?");
  q.addBindValue(QDate::currentDate().toString("yyyy-MM-dd"));
  q.exec();
  return q.next() ? q.value(0).toInt() : 0;
}

QVariantList HistoryManager::dailySummary() const {
  QVariantList out;
  if (!m_db.isOpen()) {
    return out;
  }
  QSqlQuery q(m_db);
  q.exec(
      R"(
      select date, count(*) as tests, max(wpm) as best_wpm
      from results
      group by date 
      order by date asc
      )");

  while (q.next()) {
    QVariantMap row;
    row["date"] = q.value(0).toString();
    row["tests"] = q.value(1).toInt();
    row["bestWpm"] = q.value(2).toDouble();
    out.append(row);
  }
  return out;
}

// streaks
int HistoryManager::currentStreak() const {
  if (!m_db.isOpen()) {
    return 0;
  }
  QSqlQuery q(m_db);
  q.exec("select distinct date from results order by date desc");
  QVector<QDate> dates;
  while (q.next()) {
    dates.append(QDate::fromString(q.value(0).toString(), "yyyy-MM-dd"));
  }
  if (dates.isEmpty()) {
    return 0;
  }

  const QDate today = QDate::currentDate();

  // breaking it if the most recent test is not today or yesterday
  if (dates[0] != today && dates[0] != today.addDays(-1)) {
    return 0;
  }
  int streak = 1;
  QDate cursor = dates[0];
  for (int i = 1; i < dates.size(); ++i) {
    const QDate expected = cursor.addDays(-1);
    if (dates[i] == expected) {
      streak++;
      cursor = expected;
    } else {
      break;
    }
  }
  return streak;
}

int HistoryManager::longestStreak() const {
  if (!m_db.isOpen()) {
    return 0;
  }
  QSqlQuery q(m_db);
  q.exec("select distinct date from results order by date asc");
  QVector<QDate> dates;
  while (q.next()) {
    dates.append(QDate::fromString(q.value(0).toString(), "yyyy-MM-dd"));
  }
  if (dates.isEmpty()) {
    return 0;
  }

  int longest = 1;
  int running = 1;

  for (int i = 1; i < dates.size(); ++i) {
    if (dates[i - 1].addDays(1) == dates[i]) {
      running++;
      longest = qMax(longest, running);
    } else {
      running = 1;
    }
  }
  return longest;
}
// end of streaks
