#pragma once
#include <QObject>
#include <QString>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QtSql/QSqlDatabase>

class HistoryManager : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(History)
  QML_SINGLETON

public:
  explicit HistoryManager(QObject *parent = nullptr);
  ~HistoryManager() override;

  Q_INVOKABLE void recordResult(double wpm, double rawWpm, double accuracy,
                                double consistency, int durationSeconds,
                                int correctCount, int incorrectCount,
                                int extraCount, int missedCount);

private:
  QSqlDatabase m_db;
  QString dbPath() const;
  void ensureSchema();
};
