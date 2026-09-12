#pragma once
#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QRandomGenerator>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVector>
#include <QtQmlIntegration/qqmlintegration.h>

class TypingEngine : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(bool wrapDisapbled READ wrapDisapbled WRITE setWrapDisabled NOTIFY
                 wrapDisapbledChanged)
  Q_PROPERTY(QString targetText READ targetText NOTIFY targetTextChanged)
  Q_PROPERTY(QString typedText READ typedText NOTIFY typedTextChanged)
  Q_PROPERTY(
      QVariantList wordBoundaries READ wordBoundaries NOTIFY targetTextChanged)
  Q_PROPERTY(QVariantList lines READ lines NOTIFY linesChanged)
  Q_PROPERTY(int currentLineIndex READ currentLineIndex NOTIFY lineStateChanged)
  Q_PROPERTY(int windowStart READ windowStart NOTIFY lineStateChanged)
  Q_PROPERTY(bool started READ started NOTIFY startedChanged)
  Q_PROPERTY(bool finished READ finished NOTIFY finishedChanged)
  Q_PROPERTY(int elapsedMs READ elapsedMs NOTIFY elapsedMsChanged)
  Q_PROPERTY(int testDurationSeconds READ testDurationSeconds WRITE
                 setTestDurationSeconds NOTIFY testDurationChanged)

  Q_PROPERTY(bool punctuationEnabled READ punctuationEnabled WRITE
                 setPunctuationEnabled NOTIFY punctuationEnabledChanged)
  Q_PROPERTY(int testWordCount READ testWordCount WRITE setTestWordCount NOTIFY
                 testWordCountChanged)

  // properties for counter
  Q_PROPERTY(int correctCount READ correctCount NOTIFY statsChanged)
  Q_PROPERTY(int incorrectCount READ incorrectCount NOTIFY statsChanged)
  Q_PROPERTY(int extraCount READ extraCount NOTIFY statsChanged)
  Q_PROPERTY(int missedCount READ missedCount NOTIFY statsChanged)
  Q_PROPERTY(int mistakeCount READ mistakeCount NOTIFY statsChanged)
  // end of properties for counter

  // main [responsible for calculation and such]
  Q_PROPERTY(double wpm READ wpm NOTIFY statsChanged)
  Q_PROPERTY(double rawWpm READ rawWpm NOTIFY statsChanged)
  Q_PROPERTY(double accuracy READ accuracy NOTIFY statsChanged)
  Q_PROPERTY(double consistency READ consistency NOTIFY statsChanged)
  Q_PROPERTY(QVariantList wpmHistory READ wpmHistory NOTIFY historyChanged)
  // end of main
  Q_PROPERTY(int currentWordExtraCount READ currentWordExtraCount NOTIFY
                 typedTextChanged)
  Q_PROPERTY(
      bool overflowInsertionEnabled READ overflowInsertionEnabled WRITE
          setOverflowInsertionEnabled NOTIFY overflowInsertionEnabledChanged)

public:
  explicit TypingEngine(QObject *parent = nullptr);

  enum CharState {
    Pending = 0,
    Correct = 1,
    Incorrect = 2,
    Current = 3,
    Extra = 4,
    Typed = 5
  };
  Q_ENUM(CharState)

  QString targetText() const;
  QString typedText() const;
  QVariantList wordBoundaries() const;
  QVariantList lines() const;
  int currentLineIndex() const;
  int windowStart() const;
  bool started() const;
  bool finished() const;
  int elapsedMs() const;

  // configuration
  int testDurationSeconds() const;
  bool punctuationEnabled() const;
  bool wrapDisapbled() const;

  int testWordCount() const;
  // end of configuration

  // stats getters
  int correctCount() const;
  int incorrectCount() const;
  int extraCount() const;
  int missedCount() const;
  int mistakeCount() const;
  // end of stats getters
  int currentWordExtraCount() const;

  // main getter
  double wpm() const;
  double rawWpm() const;
  double accuracy() const;
  double consistency() const;
  QVariantList wpmHistory() const;
  // end of main getters
  bool overflowInsertionEnabled() const;

  Q_INVOKABLE void setOverflowInsertionEnabled(bool enabled);
  Q_INVOKABLE void startTest(const QStringList &wordPool);
  Q_INVOKABLE void typeCharacter(const QString &ch);
  Q_INVOKABLE QString originalMistypeAt(int index) const;
  Q_INVOKABLE void deleteBackward(bool wholeWord = false);
  Q_INVOKABLE int characterStateAt(int index) const;
  Q_INVOKABLE QString characterAt(int index) const;

  // configuration
  Q_INVOKABLE void setWrapDisabled(bool disabled);
  Q_INVOKABLE void setTestDurationSeconds(int seconds);
  Q_INVOKABLE void setPunctuationEnabled(bool enabled);
  Q_INVOKABLE void setViewportWidth(qreal width);
  Q_INVOKABLE void setWordWidth(int wordStart, int wordEnd, qreal width);
  Q_INVOKABLE void setLinesVisible(int count);

  Q_INVOKABLE void setTestWordCount(int count);
  // end of configuration

  // mode
  Q_INVOKABLE void startQuoteTest(const QString &quoteText);
  Q_INVOKABLE void startWordCountTest(const QStringList &wordPool,
                                      int wordCount);
  Q_INVOKABLE void repeatTest();
  // end of mode

  Q_INVOKABLE bool wasErrorAt(int index) const;

signals:
  void targetTextChanged();
  void typedTextChanged();
  void linesChanged();
  void lineStateChanged();
  void startedChanged();
  void finishedChanged();
  void elapsedMsChanged();
  void wordWidthCacheInvalidated();
  void overflowInsertionEnabledChanged();

  // configuration
  void testDurationChanged();
  void punctuationEnabledChanged();
  void testWordCountChanged();
  void wrapDisapbledChanged();
  // end of configuration

  // stats signal
  void statsChanged();
  // end of stats signal

  void historyChanged();

private:
  struct LineRange {
    int start;
    int end;
  };

  struct CharMeta {
    bool isExtra = false;
    bool permanentError = false;
    bool counted = false;
    QChar originalMistype;
  };

  mutable QVector<QPair<int, int>> m_cachedWordBoundaries;
  mutable int m_boundaryScanPos = 0;
  QString m_targetText;
  QString m_typedText;

  bool m_started = false;
  bool m_finished = false;
  int m_testDurationSeconds = 60;
  int m_frozenElapsedMs = 0;

  bool m_wordCountMode = false;
  int m_testWordCount = 25;

  QElapsedTimer m_elapsedTimer;
  QTimer m_tickTimer;

  int m_lockedIndex = 0;
  int m_wordExtraCount = 0;

  static constexpr int kMaxExtraPerWord = 10;
  static const QChar kExtraPlaceholder;

  qreal m_viewportWidth = 0;
  int m_linesVisible = 3;
  QHash<qint64, qreal> m_wordWidths;
  QVector<LineRange> m_lines;
  int m_currentLineIndex = 0;
  int m_windowStart = 0;

  // stats related
  QVector<CharMeta> m_charMeta;
  int m_correctCount = 0;
  int m_incorrectCount = 0;
  int m_extraCount = 0;
  int m_missedCount = 0;
  int m_permanentMistakeCount = 0;

  int m_wpmCorrectKetstrokes = 0;
  int m_totalAttemptedKeystrokes = 0;
  // end of stats related

  // configuration
  bool m_wrapDisabled = false;
  bool m_punctuationEnabled = false;
  bool m_captilizeNext = true;
  // end of configuration

  QVector<QVariantMap> m_history;
  int m_lastHistorySecond = -1;
  int m_lastSampledMistakeCount = 0;

  // quote
  bool m_quoteMode = false;
  // end of quote

  bool m_overflowInsertionEnabled = true;

  QStringList m_wordPool;
  QString m_lastWord;
  static constexpr int kBufferAheadChars = 400;
  static constexpr int kWordsPerChunk = 20;

  QString randomWord() const;
  void ensureBuffer();
  void resetState();
  void invalidateBoundaryCache();

  void ensureCapacity(int len);
  int previousWordStart(int before) const;
  void commitWord();
  void finish();
  void scoreRange(int start, int end);

  static qint64 wordKey(int start, int end);
  qreal wordWidthFor(int start, int end) const;
  void rewrapLines();
  void updateLineState();

  // configuration helper
  QString applyPunctuation(const QString &word);
  //  end configuration helper

  // stats related methods
  void scoreChar(int index, bool correct, QChar typedCh, bool isExtraChar,
                 bool isMissed);
  bool wordHasError(int wordStart, int wordEnd) const;
  bool unlockPreviousWord();
  // end of stats related methods
};
