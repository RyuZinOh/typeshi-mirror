#include "./HistoryManager.hpp"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQuery>

namespace {
double applySoftCap(double value, double softCap, double factor) {
  if (value <= softCap) {
    return value;
  }
  return softCap + (value - softCap) * factor;
}
} // namespace

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
  ensureSchema();
  refreshStats();
}

HistoryManager::~HistoryManager() {
  if (m_db.isOpen()) {
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
  punctuation_enabled integer not null default 0,
  word_list text not null default 'english'
  )
  )");
  if (!ok) {
    qWarning() << "HistoryManager: failed to create table: "
               << q.lastError().text();
  }

  // migration: add word_list to pre-existing dbs that predate this column
  bool hasWordList = false;
  QSqlQuery pragma(m_db);
  pragma.exec("PRAGMA table_info(results)");
  while (pragma.next()) {
    if (pragma.value(1).toString() == "word_list") {
      hasWordList = true;
      break;
    }
  }
  if (!hasWordList) {
    qDebug() << "HistoryManager: migrating db, adding word_list column";
    QSqlQuery alter(m_db);
    if (!alter.exec("alter table results add column word_list text not null "
                    "default 'english'")) {
      qWarning() << "HistoryManager: migration failed: "
                 << alter.lastError().text();
    }
  }

  // indexing
  q.exec("create index if not exists idx_results_date on results(date)");
  q.exec(R"(
  create index if not exists idx_results_mode_dur_punct on results(mode, duration_seconds, punctuation_enabled)
  )");
  q.exec(R"(
  create index if not exists idx_results_mode_words_punct on results(mode, word_count, punctuation_enabled)
  )");
  q.exec(R"(
  create index if not exists idx_results_wordlist on results(word_list)
  )");
}

QVariantMap HistoryManager::computeStatsSummary() const {
  QVariantMap out;
  if (!m_db.isOpen()) {
    return out;
  }
  // time mode
  mergeGroupedBests(out, "english", "duration_seconds", false);
  // word mode
  mergeGroupedBests(out, "words", "word_count", false);
  // quote mode
  QSqlQuery q(m_db);
  q.prepare(R"(select wpm, accuracy from results where mode = ?
      order by wpm desc 
      limit 1
      )");
  q.addBindValue("quote");
  q.exec();
  if (q.next()) {
    out["quote"] = q.value(0).toDouble();
    out["quote_acc"] = q.value(1).toDouble();
  }
  // word list
  mergeGroupedBests(out, "english", "duration_seconds", true);
  mergeGroupedBests(out, "words", "word_count", true);

  return out;
}

double HistoryManager::computeBestWpm() const {
  if (!m_db.isOpen()) {
    return 0.0;
  }
  QSqlQuery q(m_db);
  q.exec("select max(wpm) from results");
  return q.next() ? q.value(0).toDouble() : 0.0;
}

int HistoryManager::computeTestsToday() const {
  if (!m_db.isOpen()) {
    return 0;
  }
  QSqlQuery q(m_db);
  q.exec("select count(*) from results where date  = ?");
  q.addBindValue(QDate::currentDate().toString("yyyy-MM-dd"));
  q.exec();
  return q.next() ? q.value(0).toInt() : 0;
}

void HistoryManager::mergeGroupedBests(QVariantMap &out, const QString &mode,
                                       const QString &keyCol,
                                       bool includeWordList) const {
  QSqlQuery q(m_db);
  if (!includeWordList) {
    q.prepare(QString(R"(
    select %1, punctuation_enabled, max(wpm) from results where mode = ? 
    group by %1, punctuation_enabled
    )")
                  .arg(keyCol));
    q.addBindValue(mode);
    q.exec();

    while (q.next()) {
      const int keyVal = q.value(0).toInt();
      const int punct = q.value(1).toInt();
      out[QString("%1_%2_%3").arg(mode).arg(keyVal).arg(punct)] =
          q.value(2).toDouble();
    }
    return;
  }
  q.prepare(QString(R"(
  select %1, punctuation_enabled, word_list, wpm, accuracy from results
  where mode = ? and (%1, punctuation_enabled, word_list, wpm) in (
  select %1, punctuation_enabled, word_list, max(wpm) from results where mode = ?
  group by %1, punctuation_enabled, word_list )
  )")
                .arg(keyCol));
  q.addBindValue(mode);
  q.addBindValue(mode);
  q.exec();

  while (q.next()) {
    const int keyVal = q.value(0).toInt();
    const int punct = q.value(1).toInt();
    const QString wordList = q.value(2).toString();
    const QString key =
        QString("%1_%2_%3_%4").arg(mode).arg(keyVal).arg(punct).arg(wordList);
    out[key] = q.value(3).toDouble();
    out[key + "_acc"] = q.value(4).toDouble();
  }
}
// streaks
int HistoryManager::computeCurrentStreak() const {
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

int HistoryManager::computeLongestStreak() const {
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

void HistoryManager::refreshStats() {
  m_cachedStats = computeStatsSummary();
  m_cachedBestWpm = computeBestWpm();
  m_cachedTestsToday = computeTestsToday();
  m_cachedCurrentStreak = computeCurrentStreak();
  m_cachedNWpm = computeNWpm();
  m_cachedLongestStreak = computeLongestStreak();
}

void HistoryManager::recordResult(double wpm, double rawWpm, double accuracy,
                                  double consistency, int durationSeconds,
                                  int correctCount, int incorrectCount,
                                  int extraCount, int missedCount,
                                  const QString &mode, bool punctuationEnabled,
                                  int wordCount, const QString &wordList) {
  if (!m_db.isOpen()) {
    qWarning() << "HistoryManager: db not open, can't record result";
    return;
  }

  const QDateTime now = QDateTime::currentDateTime();
  QSqlQuery q(m_db);
  q.prepare(R"(
  insert into results (timestamp, date, wpm, raw_wpm, accuracy, consistency, duration_seconds,word_count,correct_count, incorrect_count, extra_count, missed_count, mode, punctuation_enabled, word_list) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
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
  q.addBindValue(wordList);

  if (!q.exec()) {
    qWarning() << "HistoryManager: insert failed: " << q.lastError().text();
  }
  refreshStats();
  emit historyChanged();
}

double HistoryManager::bestWpmFor(const QString &mode, int durationSeconds,
                                  int punctuationEnabled, int wordCount,
                                  const QString &wordList) const {
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
  if (!wordList.isEmpty()) {
    sql += " and word_list = ?";
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
  if (!wordList.isEmpty()) {
    q.addBindValue(wordList);
  }

  q.exec();
  return q.next() ? q.value(0).toDouble() : 0.0;
}

double HistoryManager::bestWpmForWords(int wordCount, int punctuationEnabled,
                                       const QString &wordList) const {
  return bestWpmFor("words", 0, punctuationEnabled, wordCount, wordList);
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

double HistoryManager::recencyWeight(double daysAgo, double halfLifeDays) {
  double gracePeriod = 2.0;
  double u = qMax(0.0, daysAgo - gracePeriod);
  double lambda = std::log(0.5) / halfLifeDays;
  return std::exp(lambda * u);
}

double HistoryManager::computeNWpm() const {
  if (!m_db.isOpen()) {
    return 0.0;
  }
  QSqlQuery q(m_db);
  q.prepare(R"(
  select avg(wpm), date from results where mode ='english' 
  group by date
  order by date desc
  limit 100
  )");
  q.exec();
  QDate today = QDate::currentDate();
  double halfLifeDays = 7.0;
  double weightedSum = 0.0;
  double weightTotal = 0.0;

  while (q.next()) {
    double avgWpm = q.value(0).toDouble();
    QString dateStr = q.value(1).toString();
    QDate xplict = QDate::fromString(dateStr, "yyyy-MM-dd");
    double daysAgo = xplict.daysTo(today);

    double w = recencyWeight(daysAgo, halfLifeDays);
    weightedSum += w * avgWpm;
    weightTotal += w;
  }
  // for (int i = 0; i < 11; i++) {
  // double w = recencyWeight(i, 7.0);
  // qDebug() << i << "day -> weight: " << w;
  // }
  double rawNwpm = weightTotal > 0.0 ? weightedSum / weightTotal : 0.0;
  return applySoftCap(rawNwpm, 80.0, 0.5);
}
// getters
double HistoryManager::bestWpm() const { return m_cachedBestWpm; }
double HistoryManager::nWpm() const { return m_cachedNWpm; }
int HistoryManager::testsToday() const { return m_cachedTestsToday; }
int HistoryManager::currentStreak() const { return m_cachedCurrentStreak; }
int HistoryManager::longestStreak() const { return m_cachedLongestStreak; }
QVariantMap HistoryManager::statsSummary() const { return m_cachedStats; }
// end of getters
