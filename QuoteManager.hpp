#pragma once
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>

class QuoteManager : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Quotes)
  QML_SINGLETON
  Q_PROPERTY(int count READ count NOTIFY quotesChanged)

public:
  explicit QuoteManager(QObject *parent = nullptr);

  int count() const;

  Q_INVOKABLE QVariantMap randomQuote();
  Q_INVOKABLE QVariantMap quoteAt(int index) const;

signals:
  void quotesChanged();

private:
  struct Quote {
    QString text;
    QString author;
  };
  QVector<Quote> m_quotes;
  QVector<int> m_bag;
  int m_bagPos = 0;

  void load();
  void refillBag();
};
