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

private:
  QSqlDatabase m_db;
  QString dbPath() const;
};
