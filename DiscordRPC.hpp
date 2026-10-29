#pragma once
#include <QFileSystemWatcher>
#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
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

  QLocalSocket m_socket;
  QFileSystemWatcher m_dirWatcher;
  QByteArray m_buffer;
  QStringList m_candidates;
  int m_candidateIdx = -1;

  bool m_enabled = false;
  bool m_ready = false;
  bool m_attemptConnected = false;

  State m_state = State::None;
  qint64 m_typingStart = 0;

  QJsonObject m_pending;
  bool m_hasPending = false;
  QByteArray m_lastKey;

  void watchRuntimeDirs();
  void connectToDiscord();
  void tryNextCandidate();
  void teardown();
  void onConnected();
  void onReadyRead();
  void handleFrame(quint32 op, const QByteArray &data);
  void send(quint32 op, const QJsonObject &payload);

  void publish(const QString &details, const QString &state, qint64 start = 0,
               qint64 end = 0);
  void sendActivity();
};
