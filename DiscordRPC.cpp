#include "./DiscordRPC.hpp"
#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QFileInfo>
#include <QJsonDocument>
#include <QUuid>
#include <QtEndian>

namespace {
constexpr auto kClientId = "1565031824369909830";

QStringList runtimeDirs() {
  const QString runtime = qEnvironmentVariable("XDG_RUNTIME_DIR");
  if (runtime.isEmpty()) {
    return {};
  }
  return {runtime, runtime + "/app/com.discordapp.Discord",
          runtime + "/snap.discord"};
}
} // namespace

DiscordRPC::DiscordRPC(QObject *parent) : QObject(parent) {
  m_flushTimer.setSingleShot(true);
  connect(&m_flushTimer, &QTimer::timeout, this, &DiscordRPC::flush);

  connect(&m_dirWatcher, &QFileSystemWatcher::directoryChanged, this,
          [this](const QString &) {
            if (m_enabled &&
                m_socket.state() == QLocalSocket::UnconnectedState) {
              connectToDiscord();
            }
          });

  connect(&m_socket, &QLocalSocket::connected, this, &DiscordRPC::onConnected);
  connect(&m_socket, &QLocalSocket::readyRead, this, &DiscordRPC::onReadyRead);
  connect(&m_socket, &QLocalSocket::disconnected, this, [this] { teardown(); });
  connect(&m_socket, &QLocalSocket::errorOccurred, this,
          [this](QLocalSocket::LocalSocketError) {
            if (!m_attemptConnected) {
              tryNextCandidate();
            }
          });
}

DiscordRPC::~DiscordRPC() {
  m_enabled = false;
  m_flushTimer.stop();
  m_socket.abort();
}

void DiscordRPC::setEnabled(bool enabled) {
  if (enabled == m_enabled) {
    return;
  }
  m_enabled = enabled;

  if (enabled) {
    m_sessionStart = QDateTime::currentSecsSinceEpoch();
    watchRuntimeDirs();
    connectToDiscord();
    return;
  }

  m_flushTimer.stop();
  m_socket.abort();
  teardown();
  m_results.clear();
  m_latest = {};
  m_latestKey.clear();
  m_hasLatest = false;
  m_sentKey.clear();
  if (!m_dirWatcher.directories().isEmpty()) {
    m_dirWatcher.removePaths(m_dirWatcher.directories());
  }
}

void DiscordRPC::watchRuntimeDirs() {
  for (const QString &dir : runtimeDirs()) {
    if (QFileInfo(dir).isDir() && !m_dirWatcher.directories().contains(dir)) {
      m_dirWatcher.addPath(dir);
    }
  }
}

void DiscordRPC::connectToDiscord() {
  if (!m_enabled || m_socket.state() != QLocalSocket::UnconnectedState) {
    return;
  }
  m_candidates.clear();
  for (const QString &dir : runtimeDirs()) {
    for (int i = 0; i < 10; ++i) {
      const QString path = QString("%1/discord-ipc-%2").arg(dir).arg(i);
      if (QFileInfo::exists(path)) {
        m_candidates.append(path);
      }
    }
  }
  m_candidateIdx = -1;
  m_attemptConnected = false;
  tryNextCandidate();
}

void DiscordRPC::tryNextCandidate() {
  if (!m_enabled) {
    return;
  }
  m_socket.abort();
  if (++m_candidateIdx >= m_candidates.size()) {
    return;
  }
  m_socket.connectToServer(m_candidates.at(m_candidateIdx));
}

void DiscordRPC::teardown() {
  m_buffer.clear();
  m_flushTimer.stop();
  m_sentKey.clear();
  if (m_ready) {
    m_ready = false;
    emit connectedChanged();
  }
}

void DiscordRPC::onConnected() {
  m_attemptConnected = true;
  send(Handshake, QJsonObject{{"v", 1}, {"client_id", kClientId}});
}

void DiscordRPC::send(quint32 op, const QJsonObject &payload) {
  const QByteArray json = QJsonDocument(payload).toJson(QJsonDocument::Compact);
  QByteArray frame(8, '\0');
  qToLittleEndian<quint32>(op, frame.data());
  qToLittleEndian<quint32>(static_cast<quint32>(json.size()), frame.data() + 4);
  frame.append(json);
  m_socket.write(frame);
}

void DiscordRPC::onReadyRead() {
  m_buffer.append(m_socket.readAll());
  while (m_buffer.size() >= 8) {
    const quint32 op = qFromLittleEndian<quint32>(m_buffer.constData());
    const quint32 len = qFromLittleEndian<quint32>(m_buffer.constData() + 4);
    if (static_cast<quint32>(m_buffer.size()) < 8 + len) {
      return;
    }
    const QByteArray data = m_buffer.mid(8, len);
    m_buffer.remove(0, 8 + len);
    handleFrame(op, data);
  }
}

void DiscordRPC::handleFrame(quint32 op, const QByteArray &data) {
  switch (op) {
  case Ping:
    send(Pong, QJsonDocument::fromJson(data).object());
    break;
  case Close:
    qWarning().noquote() << "[rpc] server sent CLOSE:" << data;
    m_socket.abort();
    break;
  case Frame: {
    const QJsonObject obj = QJsonDocument::fromJson(data).object();
    const QString evt = obj.value("evt").toString();
    if (evt == "READY") {
      m_ready = true;
      emit connectedChanged();
      requestFlush();
    } else if (evt == "ERROR") {
      qWarning().noquote() << "[rpc] ERROR:" << obj;
    }
    break;
  }
  default:
    break;
  }
}

void DiscordRPC::setIdle(const QString &testLabel) {
  m_state = State::Idle;
  m_typingStart = 0;
  if (!m_enabled) {
    return;
  }
  publish("Idle", testLabel, m_sessionStart);
}

void DiscordRPC::setTyping(const QString &username, const QString &testLabel,
                           int durationSeconds) {
  if (m_state != State::Typing) {
    m_typingStart = QDateTime::currentSecsSinceEpoch();
  }
  m_state = State::Typing;
  if (!m_enabled) {
    return;
  }
  const qint64 end = durationSeconds > 0 ? m_typingStart + durationSeconds : 0;
  publish(username + " is typeShitting", testLabel, m_typingStart, end);
}

void DiscordRPC::setFinished(const QString &testLabel, double wpm,
                             double accuracy, double consistency) {
  m_state = State::Finished;
  m_typingStart = 0;
  if (!m_enabled) {
    return;
  }
  const QString stats = QString("%1 wpm · %2% acc · %3% con")
                            .arg(qRound(wpm))
                            .arg(qRound(accuracy))
                            .arg(qRound(consistency));
  publish("Finished " + testLabel, stats, m_sessionStart, 0, true);
}

void DiscordRPC::publish(const QString &details, const QString &state,
                         qint64 start, qint64 end, bool isResult) {
  QJsonObject activity{{"details", details},
                       {"state", state},
                       {"assets", QJsonObject{{"large_image", "typeshi"},
                                              {"large_text", "typeShi"}}}};

  QJsonObject timestamps;
  if (start > 0) {
    timestamps["start"] = start;
  }
  if (end > 0) {
    timestamps["end"] = end;
  }
  if (!timestamps.isEmpty()) {
    activity["timestamps"] = timestamps;
  }

  const QByteArray key = QJsonDocument(activity).toJson(QJsonDocument::Compact);

  if (isResult) {
    if (!m_results.isEmpty() && m_results.last().key == key) {
      return;
    }
    m_results.append({activity, key});
    while (m_results.size() > kMaxQueuedResults) {
      m_results.removeFirst();
    }
  } else if (m_hasLatest && key == m_latestKey) {
    return;
  }

  m_latest = activity;
  m_latestKey = key;
  m_hasLatest = true;

  requestFlush();
}

bool DiscordRPC::hasWork() const {
  return !m_results.isEmpty() || (m_hasLatest && m_latestKey != m_sentKey);
}

void DiscordRPC::requestFlush() {
  if (!m_enabled) {
    return;
  }
  if (m_ready) {
    if (hasWork()) {
      m_flushTimer.start(kDebounceMs);
    }
  } else if (m_socket.state() == QLocalSocket::UnconnectedState) {
    connectToDiscord();
  }
}

void DiscordRPC::flush() {
  if (!m_enabled || !m_ready) {
    return;
  }

  while (!m_results.isEmpty() && m_results.first().key == m_sentKey) {
    m_results.removeFirst();
  }

  if (!hasWork()) {
    return;
  }

  if (m_sendClock.isValid()) {
    const qint64 elapsed = m_sendClock.elapsed();
    if (elapsed < kMinIntervalMs) {
      m_flushTimer.start(static_cast<int>(kMinIntervalMs - elapsed) + 100);
      return;
    }
  }

  QJsonObject next;
  QByteArray nextKey;
  if (!m_results.isEmpty()) {
    next = m_results.first().activity;
    nextKey = m_results.first().key;
    m_results.removeFirst();
  } else {
    next = m_latest;
    nextKey = m_latestKey;
  }

  sendActivity(next);
  m_sendClock.restart();
  m_sentKey = nextKey;

  if (hasWork()) {
    m_flushTimer.start(static_cast<int>(kMinIntervalMs) + 100);
  }
}

void DiscordRPC::sendActivity(const QJsonObject &activity) {
  QJsonObject act = activity;
  QJsonObject timestamps = act.value("timestamps").toObject();
  if (timestamps.contains("end")) {
    const qint64 end = static_cast<qint64>(timestamps.value("end").toDouble());
    if (end <= QDateTime::currentSecsSinceEpoch()) {
      timestamps.remove("end");
      if (timestamps.isEmpty()) {
        act.remove("timestamps");
      } else {
        act["timestamps"] = timestamps;
      }
    }
  }

  send(Frame,
       QJsonObject{
           {"cmd", "SET_ACTIVITY"},
           {"args", QJsonObject{{"pid", QCoreApplication::applicationPid()},
                                {"activity", act}}},
           {"nonce", QUuid::createUuid().toString(QUuid::WithoutBraces)}});
}
