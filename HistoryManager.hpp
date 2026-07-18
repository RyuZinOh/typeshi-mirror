#pragma once
#include <QObject>
#include <QString>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QtSql/QSqlDatabase>

class HistoryManager : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(History)
  QML_SINGLETON

  Q_PROPERTY(double bestWpm READ bestWpm NOTIFY historyChanged)
  Q_PROPERTY(int testsToday READ testsToday NOTIFY historyChanged)
  Q_PROPERTY(int currentStreak READ currentStreak NOTIFY historyChanged)

public:
  explicit HistoryManager(QObject *parent = nullptr);
  ~HistoryManager() override;

  Q_INVOKABLE void recordResult(double wpm, double rawWpm, double accuracy,
                                double consistency, int durationSeconds,
                                int correctCount, int incorrectCount,
                                int extraCount, int missedCount);
  Q_INVOKABLE QVariantList dailySummary() const;

  double bestWpm() const;
  int testsToday() const;
  int currentStreak() const;

signals:
  void historyChanged();

private:
  QSqlDatabase m_db;
  QString dbPath() const;
  void ensureSchema();
};
