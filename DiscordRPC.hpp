#pragma once
#include <QElapsedTimer>
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QList>
#include <QLocalSocket>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QtQmlIntegration/qqmlintegration.h>

class DiscordRPC : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Discord)
  QML_SINGLETON
  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
  explicit DiscordRPC(QObject *parent = nullptr);
  ~DiscordRPC() override;

  bool connected() const { return m_ready; }

  Q_INVOKABLE void setEnabled(bool enabled);
  Q_INVOKABLE void setIdle(const QString &testLabel);
  Q_INVOKABLE void setTyping(const QString &username, const QString &testLabel,
                             int durationSeconds = 0);
  Q_INVOKABLE void setFinished(const QString &testLabel, double wpm,
                               double accuracy, double consistency);

signals:
  void connectedChanged();

private:
  enum Opcode : quint32 {
    Handshake = 0,
    Frame = 1,
    Close = 2,
    Ping = 3,
    Pong = 4
  };
  enum class State { None, Idle, Typing, Finished };

  struct Queued {
    QJsonObject activity;
    QByteArray key;
  };

  static constexpr qint64 kMinIntervalMs = 16000;
  static constexpr int kDebounceMs = 300;
  static constexpr int kMaxQueuedResults = 3;

  QLocalSocket m_socket;
  QFileSystemWatcher m_dirWatcher;
  QTimer m_flushTimer;
  QElapsedTimer m_sendClock;
  QByteArray m_buffer;
  QStringList m_candidates;
  int m_candidateIdx = -1;

  bool m_enabled = false;
  bool m_ready = false;
  bool m_attemptConnected = false;

  State m_state = State::None;
  qint64 m_typingStart = 0;
  qint64 m_sessionStart = 0;

  QList<Queued> m_results;
  QJsonObject m_latest;
  QByteArray m_latestKey;
  bool m_hasLatest = false;
  QByteArray m_sentKey;

  void watchRuntimeDirs();
  void connectToDiscord();
  void tryNextCandidate();
  void teardown();
  void onConnected();
  void onReadyRead();
  void handleFrame(quint32 op, const QByteArray &data);
  void send(quint32 op, const QJsonObject &payload);

  void publish(const QString &details, const QString &state, qint64 start = 0,
               qint64 end = 0, bool isResult = false);
  bool hasWork() const;
  void requestFlush();
  void flush();
  void sendActivity(const QJsonObject &activity);
};
