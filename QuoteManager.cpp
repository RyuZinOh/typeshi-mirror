#include "./QuoteManager.hpp"
#include <QDebug>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <algorithm>

QuoteManager::QuoteManager(QObject *parent) : QObject(parent) { load(); }

void QuoteManager::load() {
  m_quotes.clear();

  QFile file(
      QStringLiteral(":/qt/qml/typeShitter/application/assets/quotes.json"));
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    qWarning() << "QuoteManager: quotes.json dont exist...";
    emit quotesChanged();
    return;
  }

  QJsonParseError err;
  const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
  if (err.error != QJsonParseError::NoError || !doc.isObject()) {
    qWarning() << "QuoteManager: bad quotes.json:" << err.errorString();
    emit quotesChanged();
    return;
  }

  const QJsonArray arr = doc.object().value("quotes").toArray();
  for (const QJsonValue &v : arr) {
    const QJsonObject o = v.toObject();
    const QString text = o.value("text").toString().trimmed();
    if (text.isEmpty()) {
      continue;
    }
    m_quotes.append({text, o.value("author").toString()});
  }

  refillBag();
  emit quotesChanged();
}

void QuoteManager::refillBag() {
  m_bag.resize(m_quotes.size());
  for (int i = 0; i < m_bag.size(); i++) {
    m_bag[i] = i;
  }
  std::shuffle(m_bag.begin(), m_bag.end(), *QRandomGenerator::global());
  m_bagPos = 0;
}

int QuoteManager::count() const { return m_quotes.size(); }

QVariantMap QuoteManager::randomQuote() {
  QVariantMap out;
  if (m_quotes.isEmpty()) {
    out["text"] = QStringLiteral("No quotes loaded.");
    out["author"] = QString();
    return out;
  }

  if (m_bagPos >= m_bag.size()) {
    refillBag();
  }

  const int idx = m_bag.at(m_bagPos);
  m_bagPos++;

  const Quote &q = m_quotes.at(idx);
  QString fullText = q.text;
  if (!q.author.isEmpty()) {
    fullText += QStringLiteral(" by ") + q.author;
  }

  out["text"] = fullText;
  out["author"] = q.author;
  return out;
}

QVariantMap QuoteManager::quoteAt(int index) const {
  QVariantMap out;
  if (index < 0 || index >= m_quotes.size()) {
    return out;
  }
  const Quote &q = m_quotes.at(index);
  QString fullText = q.text;
  if (!q.author.isEmpty()) {
    fullText += QStringLiteral(" by ") + q.author;
  }
  out["text"] = fullText;
  out["author"] = q.author;
  return out;
}
