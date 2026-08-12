#pragma once
#include <QObject>
#include <QStringList>
#include <QtQmlIntegration/qqmlintegration.h>

class FuzzyFinder : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(FuzzyFinder)
  QML_SINGLETON

public:
  explicit FuzzyFinder(QObject *parent = nullptr);
  Q_INVOKABLE QStringList search(const QString &term,
                                 const QStringList &items) const;

private:
  static bool fuzzyMatch(const QString &needle, const QString &haystack,
                         int &score);
};
