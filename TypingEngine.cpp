#include "./TypingEngine.hpp"
#include <QRandomGenerator>
#include <cmath>

// marker
const QChar TypingEngine::kExtraPlaceholder(0x2063);

TypingEngine::TypingEngine(QObject *parent) : QObject(parent) {
  m_tickTimer.setInterval(100);
  connect(&m_tickTimer, &QTimer::timeout, this, [this]() {
    if (m_started && !m_finished && !m_quoteMode && !m_wordCountMode &&
        elapsedMs() >= m_testDurationSeconds * 1000) {
      finish();
      return;
    }
    if (m_started && !m_finished) {
      // history sampling
      int sec = elapsedMs() / 1000;
      if (sec > 0 && sec != m_lastHistorySecond) {
        m_lastHistorySecond = sec;
        QVariantMap point;
        point["time"] = sec;
        point["wpm"] = wpm();
        point["rawWpm"] = rawWpm();
        point["hasError"] = m_permanentMistakeCount > m_lastSampledMistakeCount;
        m_lastSampledMistakeCount = m_permanentMistakeCount;
        m_history.append(point);
        emit historyChanged();
      }
      // end of history sampling

      // quotes completion / wordCount mode
      if ((m_quoteMode || m_wordCountMode) &&
          m_typedText.length() >= m_targetText.length()) {
        finish();
        return;
      }
      // end of quotes completion /wordCount mode

      emit elapsedMsChanged();
    }
  });
}

bool TypingEngine::punctuationEnabled() const { return m_punctuationEnabled; }
bool TypingEngine::started() const { return m_started; }
bool TypingEngine::finished() const { return m_finished; }
QString TypingEngine::targetText() const { return m_targetText; }
QString TypingEngine::typedText() const { return m_typedText; }
int TypingEngine::testWordCount() const { return m_testWordCount; }
int TypingEngine::currentWordExtraCount() const { return m_wordExtraCount; }

void TypingEngine::setTestWordCount(int count) {
  if (count <= 0 || count == m_testWordCount) {
    return;
  }
  m_testWordCount = count;
  emit testWordCountChanged();
}

void TypingEngine::setPunctuationEnabled(bool enabled) {
  if (enabled == m_punctuationEnabled) {
    return;
  }
  m_punctuationEnabled = enabled;
  emit punctuationEnabledChanged();
}

void TypingEngine::startQuoteTest(const QString &quoteText) {
  resetState();
  m_quoteMode = true;
  m_targetText = quoteText.trimmed();
  m_isExtra.assign(m_targetText.length(), false);

  emit targetTextChanged();
  emit typedTextChanged();
  emit startedChanged();
  emit finishedChanged();
  emit historyChanged();
  emit elapsedMsChanged();
  emit statsChanged();
  rewrapLines();
}

void TypingEngine::startWordCountTest(const QStringList &wordPool,
                                      int wordCount) {
  resetState();
  m_quoteMode = false;
  m_wordCountMode = true;
  m_wordPool = wordPool;
  m_testWordCount = wordCount > 0 ? wordCount : m_testWordCount;

  for (int i = 0; i < m_testWordCount; ++i) {
    if (!m_targetText.isEmpty()) {
      m_targetText.append(' ');
    }
    QString word = randomWord();
    m_targetText.append(applyPunctuation(word));
    m_lastWord = word;
  }
  m_isExtra.assign(m_targetText.length(), false);

  emit targetTextChanged();
  emit typedTextChanged();
  emit startedChanged();
  emit finishedChanged();
  emit historyChanged();
  emit elapsedMsChanged();
  emit statsChanged();
  rewrapLines();
}
// void TypingEngine::startTest(const QStringList &wordPool) {
//   m_started = false;
//   m_finished = false;
//   m_quoteMode = false;
//   m_frozenElapsedMs = 0;
//   m_tickTimer.stop();
//
//   m_wordPool = wordPool;
//   // m_targetText = wordPool.join(' ');
//   m_lastWord.clear();
//   m_targetText.clear();
//   m_typedText.clear();
//   m_isExtra.clear();
//   m_lockedIndex = 0;
//   m_wordExtraCount = 0;
//   m_wordWidths.clear();
//   m_windowStart = 0;
//   m_history.clear();
//   m_lastHistorySecond = -1;
//
//   // stats reset too
//   m_permanentError.clear();
//   m_originalMistype.clear();
//   m_countedIndicies.clear();
//   m_correctCount = 0;
//   m_incorrectCount = 0;
//   m_extraCount = 0;
//   m_missedCount = 0;
//   m_permanentMistakeCount = 0;
//   m_wpmCorrectKetstrokes = 0;
//   m_totalAttemptedKeystrokes = 0;
//
//   m_captilizeNext = true;
//
//   ensureBuffer();
//   m_isExtra.assign(m_targetText.length(), false);
//
//   emit targetTextChanged();
//   emit typedTextChanged();
//   emit startedChanged();
//   emit finishedChanged();
//   emit historyChanged();
//   emit elapsedMsChanged();
//   emit statsChanged();
//   rewrapLines();
// }
void TypingEngine::startTest(const QStringList &wordPool) {
  resetState();
  m_quoteMode = false;
  m_wordPool = wordPool;

  ensureBuffer();
  m_isExtra.assign(m_targetText.length(), false);

  emit targetTextChanged();
  emit typedTextChanged();
  emit startedChanged();
  emit finishedChanged();
  emit historyChanged();
  emit elapsedMsChanged();
  emit statsChanged();
  rewrapLines();
}

void TypingEngine::resetState() {
  m_started = false;
  m_finished = false;
  m_frozenElapsedMs = 0;
  m_tickTimer.stop();
  m_wordCountMode = false;
  m_useSeededRng = false;

  m_cachedWordBoundaries.clear();
  m_lastWord.clear();
  m_targetText.clear();
  m_typedText.clear();
  m_isExtra.clear();
  m_lockedIndex = 0;
  m_wordExtraCount = 0;
  m_wordWidths.clear();
  m_windowStart = 0;
  m_history.clear();
  m_lastHistorySecond = -1;

  m_permanentError.clear();
  m_originalMistype.clear();
  m_countedIndicies.clear();
  m_correctCount = 0;
  m_incorrectCount = 0;
  m_extraCount = 0;
  m_missedCount = 0;
  m_permanentMistakeCount = 0;
  m_wpmCorrectKetstrokes = 0;
  m_boundaryScanPos = 0;
  m_totalAttemptedKeystrokes = 0;
  m_lastSampledMistakeCount = 0;

  m_captilizeNext = true;
}

int TypingEngine::elapsedMs() const {
  if (m_finished || !m_started) {
    return m_frozenElapsedMs;
  }
  return static_cast<int>(m_elapsedTimer.elapsed());
}
int TypingEngine::testDurationSeconds() const { return m_testDurationSeconds; }

void TypingEngine::ensureCapacity(int len) {
  if (m_isExtra.size() < len) {
    m_isExtra.resize(len, false);
  }
}

int TypingEngine::previousWordStart(int before) const {
  int i = before - 1;
  if (i >= 0 && m_targetText.at(i) == ' ') {
    i--;
  }
  while (i >= 0 && m_targetText.at(i) != ' ') {
    i--;
  }
  return i + 1;
}

void TypingEngine::commitWord() {
  int wordStart = m_lockedIndex;
  int wordEnd = wordStart;

  while (wordEnd < m_targetText.length() && m_targetText.at(wordEnd) != ' ') {
    wordEnd++;
  }

  if (wordStart >= m_targetText.length() && wordStart >= m_typedText.length()) {
    return;
  }

  if (m_typedText.length() <= wordStart) {
    return;
  }
  if (m_typedText.length() < wordEnd) {
    int padCount = wordEnd - m_typedText.length();
    for (int i = 0; i < padCount; ++i) {
      m_typedText.append(
          QChar(0x2064)); // skipping placeholder, invisible spacing
    }
  }
  for (int i = wordStart; i < wordEnd; ++i) {
    bool extra = i < m_isExtra.size() && m_isExtra.at(i);
    bool skipped = m_typedText.at(i) == QChar(0x2064);
    bool correct =
        !extra && !skipped && m_typedText.at(i) == m_targetText.at(i);

    QChar typedCh = skipped ? QChar() : m_typedText.at(i);
    scoreChar(i, correct, typedCh, extra, skipped);
  }

  if (wordEnd < m_targetText.length() && m_targetText.at(wordEnd) == ' ') {
    if (m_typedText.length() <= wordEnd) {
      m_typedText.append(' ');
    }
    scoreChar(wordEnd, true, ' ', false, false);
    m_lockedIndex = wordEnd + 1;
  } else {
    m_lockedIndex = wordEnd;
  }

  m_wordExtraCount = 0;
  ensureBuffer();
  emit typedTextChanged();
  emit statsChanged();
  updateLineState();
}

void TypingEngine::typeCharacter(const QString &ch) {
  if (m_finished || ch.isEmpty()) {
    return;
  }
  if (!m_started) {
    m_started = true;
    m_elapsedTimer.start();
    m_tickTimer.start();
    emit startedChanged();
  }

  QChar typedChar = ch.at(0);
  if (typedChar == ' ') {
    commitWord();
    return;
  }

  int pos = m_typedText.length();
  if (pos >= m_targetText.length()) {
    return;
  }

  QChar expectedChar = m_targetText.at(pos);
  bool isOverflow = (expectedChar == ' ');

  if (isOverflow) {
    if (m_wordExtraCount >= kMaxExtraPerWord) {
      return;
    }
    m_targetText.insert(pos, kExtraPlaceholder);
    ensureCapacity(m_targetText.length());
    m_isExtra.insert(pos, true);
    m_wordExtraCount += 1;
    emit targetTextChanged();
  }

  m_typedText.append(typedChar);
  ensureBuffer();
  emit typedTextChanged();
  updateLineState();
}

void TypingEngine::deleteBackward(bool wholeWord) {
  if (m_typedText.isEmpty()) {
    return;
  }
  bool didSomething = false;
  do {
    int pos = m_typedText.length() - 1;
    if (pos < m_lockedIndex) {
      if (!unlockPreviousWord()) {
        break; // stay locked when correct
      }
      pos = m_typedText.length() - 1; // moving  the index point lock hanuKi..
    }
    bool wasExtra = pos < m_isExtra.size() && m_isExtra.at(pos);
    m_typedText.chop(1);

    if (wasExtra) {
      m_targetText.remove(pos, 1);
      m_isExtra.remove(pos);
      if (m_wordExtraCount > 0) {
        m_wordExtraCount -= 1;
      }
      emit targetTextChanged();
    }
    didSomething = true;
  } while (wholeWord && m_typedText.length() > m_lockedIndex);

  if (!didSomething) {
    return;
  }
  emit typedTextChanged();
  updateLineState();
}

int TypingEngine::characterStateAt(int index) const {
  if (index < 0 || index >= m_targetText.length()) {
    return Pending;
  }
  if (index < m_typedText.length()) {
    if (index < m_isExtra.size() && m_isExtra.at(index)) {
      return Extra;
    }
    return m_typedText.at(index) == m_targetText.at(index) ? Correct
                                                           : Incorrect;
  }

  if (index == m_typedText.length()) {
    return Current;
  }
  return Pending;
}

QString TypingEngine::characterAt(int index) const {
  if (index < 0 || index >= m_targetText.length()) {
    return QString();
  }
  return QString(m_targetText.at(index));
}

QVariantList TypingEngine::wordBoundaries() const {
  const int len = m_targetText.length();

  if (m_boundaryScanPos > len) {
    m_cachedWordBoundaries.clear();
    m_boundaryScanPos = 0;
  }
  int start = m_cachedWordBoundaries.isEmpty()
                  ? 0
                  : m_cachedWordBoundaries.last().second;

  for (int i = m_boundaryScanPos; i < len; ++i) {
    if (m_targetText.at(i) == ' ') {
      m_cachedWordBoundaries.append({start, i + 1});
      start = i + 1;
    }
  }
  m_boundaryScanPos = len;

  QVariantList result;
  result.reserve(m_cachedWordBoundaries.size() + 1);
  for (const auto &wb : m_cachedWordBoundaries) {
    QVariantMap entry;
    entry["start"] = wb.first;
    entry["end"] = wb.second;
    result.append(entry);
  }

  if (start < len) {
    QVariantMap entry;
    entry["start"] = start;
    entry["end"] = len;
    result.append(entry);
  }
  return result;
}

QVariantList TypingEngine::lines() const {
  QVariantList result;
  for (const auto &line : m_lines) {
    QVariantMap entry;
    entry["start"] = line.start;
    entry["end"] = line.end;
    result.append(entry);
  }
  return result;
}

int TypingEngine::currentLineIndex() const { return m_currentLineIndex; }
int TypingEngine::windowStart() const { return m_windowStart; }

qint64 TypingEngine::wordKey(int start, int end) {
  return (static_cast<qint64>(start) << 32 | static_cast<quint32>(end));
}

qreal TypingEngine::wordWidthFor(int start, int end) const {
  auto it = m_wordWidths.constFind(wordKey(start, end));
  if (it != m_wordWidths.constEnd()) {
    return it.value();
  }
  return (end - start) * 12.0;
}

void TypingEngine::setViewportWidth(qreal width) {
  m_viewportWidth = width;
  rewrapLines();
}

void TypingEngine::setWordWidth(int wordStart, int wordEnd, qreal width) {
  m_wordWidths[wordKey(wordStart, wordEnd)] = width;
}

void TypingEngine::setLinesVisible(int count) {
  if (count <= 0 || count == m_linesVisible) {
    return;
  }
  m_linesVisible = count;
  updateLineState();
}

void TypingEngine::rewrapLines() {
  if (m_viewportWidth <= 0) {
    m_lines.clear();
    emit linesChanged();
    return;
  }

  const QVariantList words = wordBoundaries();
  QVector<LineRange> result;
  int lineStart = 0;
  qreal lineWidth = 0;
  constexpr qreal KSafetyMargin = 24.0;

  for (const QVariant &wv : words) {
    const QVariantMap w = wv.toMap();
    const int wStart = w["start"].toInt();
    const int wEnd = w["end"].toInt();
    const qreal chunkWidth = wordWidthFor(wStart, wEnd);

    if (lineWidth > 0 &&
        lineWidth + chunkWidth > m_viewportWidth - KSafetyMargin) {
      result.append({lineStart, wStart});
      lineStart = wStart;
      lineWidth = 0;
    }
    lineWidth += chunkWidth;
  }
  if (lineStart < m_targetText.length()) {
    result.append({lineStart, static_cast<int>(m_targetText.length())});
  } else if (result.isEmpty()) {
    result.append({0, static_cast<int>(m_targetText.length())});
  }
  m_lines = result;
  emit linesChanged();
  updateLineState();
}

void TypingEngine::updateLineState() {
  const int cursor = m_typedText.length();
  int idx = 0;
  for (int i = 0; i < m_lines.size(); ++i) {
    if (cursor >= m_lines.at(i).start) {

      idx = i;
    } else {
      break;
    }
  }

  m_currentLineIndex = idx;
  const int secondLineIdx = m_windowStart + 1;

  if (secondLineIdx < m_lines.size()) {
    const LineRange &secondLine = m_lines.at(secondLineIdx);
    if (cursor >= secondLine.end) {
      m_windowStart = m_windowStart + 1;
    }
  }

  emit lineStateChanged();
}

void TypingEngine::finish() {
  m_finished = true;
  m_frozenElapsedMs = static_cast<int>(m_elapsedTimer.elapsed());
  m_tickTimer.stop();

  emit finishedChanged();
  emit elapsedMsChanged();
}

void TypingEngine::scoreChar(int index, bool correct, QChar typedCh,
                             bool isExtraChar, bool isMissed) {
  if (m_countedIndicies.size() <= index) {
    m_countedIndicies.resize(index + 1, false);
  }
  // !double count gatePoint
  if (m_countedIndicies.at(index)) {
    return;
  }

  m_countedIndicies[index] = true;
  m_totalAttemptedKeystrokes++;

  if (correct) {
    m_wpmCorrectKetstrokes++;
    m_correctCount++;
  } else {
    m_permanentMistakeCount++;

    if (m_permanentError.size() <= index) {
      m_permanentError.resize(index + 1, false);
    }
    m_permanentError[index] = true;

    if (m_originalMistype.size() <= index) {
      m_originalMistype.resize(index + 1, QChar());
    }
    m_originalMistype[index] = typedCh;
    if (isExtraChar) {
      m_extraCount++;
    } else if (isMissed) {
      m_missedCount++;
    } else {
      m_incorrectCount++;
    }
  }
}

// utilities for typing
bool TypingEngine::wordHasError(int wordStart, int wordEnd) const {
  for (int i = wordStart; i < wordEnd && i < m_permanentError.size(); ++i) {
    if (m_permanentError.at(i)) {
      return true;
    }
  }
  return false;
}

bool TypingEngine::unlockPreviousWord() {
  if (m_lockedIndex <= 0) {
    return false;
  }
  int wordStart = previousWordStart(m_lockedIndex);
  bool currentlyCorrect = true;
  for (int i = wordStart; i < m_lockedIndex; ++i) {
    bool extra = i < m_isExtra.size() && m_isExtra.at(i);
    bool skipped =
        i < m_typedText.length() && m_typedText.at(i) == QChar(0x2064);
    bool ok = !extra && !skipped && i < m_typedText.length() &&
              m_typedText.at(i) == m_targetText.at(i);

    if (!ok) {
      currentlyCorrect = false;
      break;
    }
  }
  if (currentlyCorrect) {
    return false;
  }
  // if (!wordHasError(wordStart, m_lockedIndex)) {
  //   return false;
  // }

  m_lockedIndex = wordStart;
  m_wordExtraCount = 0;
  emit statsChanged();

  return true;
}
// getters i guess.
int TypingEngine::correctCount() const { return m_correctCount; }
int TypingEngine::incorrectCount() const { return m_incorrectCount; }
int TypingEngine::extraCount() const { return m_extraCount; }
int TypingEngine::missedCount() const { return m_missedCount; }
int TypingEngine::mistakeCount() const { return m_permanentMistakeCount; }
// end of getters for  typing utilities

bool TypingEngine::wasErrorAt(int index) const {
  if (index < 0 || index >= m_permanentError.size()) {
    return false;
  }
  return m_permanentError.at(index);
}

QString TypingEngine::originalMistypeAt(int index) const {
  if (index < 0 || index >= m_originalMistype.size()) {
    return QString();
  }
  QChar c = m_originalMistype.at(index);
  if (c.isNull()) {
    return QString();
  }
  return QString(c);
}
//  end of utilities for typing

// calculation and main stuff
double TypingEngine::wpm() const {
  int ms = elapsedMs();
  if (ms <= 0) {
    return 0.0;
  }
  double minutes = ms / 60000.0;
  double words = m_wpmCorrectKetstrokes / 5.0;
  return words / minutes;
}

double TypingEngine::rawWpm() const {
  int ms = elapsedMs();
  if (ms <= 0) {
    return 0.0;
  }
  double minutes = ms / 60000.0;
  double words = m_totalAttemptedKeystrokes / 5.0;
  return words / minutes;
}

double TypingEngine::accuracy() const {
  if (m_totalAttemptedKeystrokes <= 0) {
    return 100.0;
  }
  double correct = m_totalAttemptedKeystrokes - m_permanentMistakeCount;
  return (correct / static_cast<double>(m_totalAttemptedKeystrokes)) * 100.0;
}

QVariantList TypingEngine::wpmHistory() const {
  QVariantList result;
  result.reserve(m_history.size());
  for (const auto &p : m_history) {
    result.append(p);
  }
  return result;
}

// consistency = how steady raw WPM stayed across the history samples...
double TypingEngine::consistency() const {
  if (m_history.size() < 2) {
    return 100.0;
  }
  QVector<double> samples;
  samples.reserve(m_history.size());
  for (const auto &p : m_history) {
    samples.append(p["rawWpm"].toDouble());
  }
  double sum = 0.0;
  for (double v : samples) {
    sum += v;
  }
  double mean = sum / samples.size();
  if (mean <= 0.0) {
    return 100.0;
  }
  double variance = 0.0;
  for (double v : samples) {
    variance += (v - mean) * (v - mean);
  }
  variance /= samples.size();
  double stddev = std::sqrt(variance);

  double cv = stddev / mean;
  double result = 100.0 * (1.0 - cv);

  if (result < 0.0) {
    result = 0.0;
  }
  if (result > 100.0) {
    result = 100.0;
  }
  return result;
}

// end of calculation and main stuff

// words when loaded
QString TypingEngine::randomWord() const {
  if (m_wordPool.isEmpty()) {
    return QStringLiteral("word");
  }
  if (m_wordPool.size() == 1) {
    return m_wordPool.first();
  }

  const int poolSize = static_cast<int>(m_wordPool.size());
  const int lastIdx = m_wordPool.indexOf(m_lastWord);

  int roll =
      m_useSeededRng
          ? static_cast<int>(m_seededRng.bounded(poolSize - 1))
          : static_cast<int>(QRandomGenerator::global()->bounded(poolSize - 1));
  int idx = (lastIdx >= 0 && roll >= lastIdx) ? roll + 1 : roll;

  return m_wordPool.at(idx);
}

QString TypingEngine::applyPunctuation(const QString &word) {
  if (!m_punctuationEnabled || word.isEmpty()) {
    return word;
  }
  QString result = word;
  auto *rng = QRandomGenerator64::global();
  if (m_captilizeNext) {
    result[0] = result[0].toUpper();
    m_captilizeNext = false;
  }
  const int roll = rng->bounded(100);
  if (roll < 6) {
    result += '.';
  } else if (roll < 9) {
    result += '?';
    m_captilizeNext = true;
  } else if (roll < 11) {
    result += '!';
    m_captilizeNext = true;
  } else if (roll < 20) {
    result += ',';
  } else if (roll < 23) {
    result += ';';
  } else if (roll < 26) {
    result += ':';
  }
  return result;
}

void TypingEngine::ensureBuffer() {
  if (m_quoteMode || m_wordCountMode) {
    return;
  }
  bool grew = false;
  while (m_targetText.length() - m_typedText.length() < kBufferAheadChars) {
    for (int i = 0; i < kWordsPerChunk; ++i) {
      if (!m_targetText.isEmpty()) {
        m_targetText.append(' ');
      }
      QString word = randomWord();
      QString displayWord = applyPunctuation(word);
      m_targetText.append(displayWord);
      m_lastWord = word;
      // m_targetText.append(word);
      // m_lastWord = word;
    }
    grew = true;
  }
  if (grew) {
    ensureCapacity(m_targetText.length());
    emit targetTextChanged();
  }
}

void TypingEngine::setTestDurationSeconds(int seconds) {
  if (seconds <= 0 || seconds == m_testDurationSeconds) {
    return;
  }
  m_testDurationSeconds = seconds;
  emit testDurationChanged();
}

// multiplayer mode
void TypingEngine::startMultiplayerTest(const QStringList &wordPool,
                                        qint64 seed, int durationSeconds) {
  resetState();
  m_quoteMode = false;
  m_wordCountMode = false;
  m_punctuationEnabled = false;
  m_wordPool = wordPool;
  m_testDurationSeconds =
      durationSeconds > 0 ? durationSeconds : m_testDurationSeconds;

  m_seededRng = QRandomGenerator(static_cast<quint32>(seed));
  m_useSeededRng = true;

  ensureBuffer();
  m_isExtra.assign(m_targetText.length(), false);

  m_started = true;
  m_elapsedTimer.start();
  m_tickTimer.start();

  emit targetTextChanged();
  emit typedTextChanged();
  emit startedChanged();
  emit finishedChanged();
  emit historyChanged();
  emit elapsedMsChanged();
  emit statsChanged();
  emit testDurationChanged();
  rewrapLines();
}
int TypingEngine::canonicalCursorIndex() const {
  int cursor = m_typedText.length();
  int extrasBefore = 0;
  for (int i = 0; i < cursor && i < m_isExtra.size(); ++i) {
    if (m_isExtra.at(i)) {
      extrasBefore++;
    }
  }
  return cursor - extrasBefore;
}

int TypingEngine::rawIndexForCanonical(int canonicalIndex) const {
  if (canonicalIndex <= 0) {
    return 0;
  }
  int seen = 0;
  int i = 0;
  for (; i < m_targetText.length(); ++i) {
    bool extra = i < m_isExtra.size() && m_isExtra.at(i);
    if (!extra) {
      seen++;
    }
    if (seen >= canonicalIndex) {
      return i + 1;
    }
  }
  return m_targetText.length();
}
// end of multiplayer modek
