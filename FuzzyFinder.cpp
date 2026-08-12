#include "./FuzzyFinder.hpp"
#include <algorithm>

FuzzyFinder::FuzzyFinder(QObject *parent) : QObject(parent) {}

bool FuzzyFinder::fuzzyMatch(const QString &needle, const QString &haystack,
                             int &score) {
  if (needle.isEmpty()) {
    score = 0;
    return true;
  }

  const QString h = haystack.toLower();
  const QString n = needle.toLower();

  int hIdx = 0;
  int gapTotal = 0;
  int consecutiveBonus = 0;
  bool prevMatched = false;

  for (int i = 0; i < n.length(); ++i) {
    const int foundAt = h.indexOf(n.at(i), hIdx);
    if (foundAt == -1) {
      return false;
    }

    const int gap = foundAt - hIdx;
    gapTotal += gap;

    if (gap == 0 && prevMatched) {
      consecutiveBonus += 3;
    }
    prevMatched = true;

    hIdx = foundAt + 1;
  }

  score = gapTotal - consecutiveBonus;
  if (h.startsWith(n)) {
    score -= 10;
  }
  score += static_cast<int>((h.length() - n.length()) * 0.05);

  return true;
}

QStringList FuzzyFinder::search(const QString &term,
                                const QStringList &items) const {
  const QString q = term.trimmed();

  if (q.isEmpty()) {
    QStringList sorted = items;
    std::sort(sorted.begin(), sorted.end(),
              [](const QString &a, const QString &b) {
                return a.compare(b, Qt::CaseInsensitive) < 0;
              });
    return sorted;
  }

  QVector<QPair<QString, int>> scored;
  scored.reserve(items.size());

  for (const QString &item : items) {
    int score = 0;
    if (fuzzyMatch(q, item, score)) {
      scored.append({item, score});
    }
  }

  std::sort(scored.begin(), scored.end(),
            [](const QPair<QString, int> &a, const QPair<QString, int> &b) {
              return a.second < b.second;
            });

  QStringList result;
  result.reserve(scored.size());
  for (const auto &pair : scored) {
    result.append(pair.first);
  }
  return result;
}
