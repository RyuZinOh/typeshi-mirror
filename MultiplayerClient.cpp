#include "./MultiplayerClient.hpp"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

MultiplayerClient::MultiplayerClient(QObject *parent) : QObject(parent) {
  connect(&m_socket, &QWebSocket::connected, this, [this]() {
    m_connected = true;
    qDebug() << "MultiplayerClient: connected";
    emit connectedChanged();
  });

  connect(&m_socket, &QWebSocket::disconnected, this, [this]() {
    m_connected = false;
    qDebug() << "MultiplayerClient: disconnected";
    emit connectedChanged();
  });

  connect(&m_socket, &QWebSocket::errorOccurred, this,
          [this](QAbstractSocket::SocketError) {
            qWarning() << "MultiplayerClient: error:" << m_socket.errorString();
          });

  connect(&m_socket, &QWebSocket::textMessageReceived, this,
          [this](const QString &message) {
            qDebug() << "MultiplayerClient: received:" << message;

            QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
            if (!doc.isObject()) {
              return;
            }
            QJsonObject obj = doc.object();
            const QString type = obj.value("type").toString();

            if (type == "created") {
              m_roomCode = obj.value("room").toString();
              emit roomCodeChanged();
            } else if (type == "error") {
              if (!m_roomCode.isEmpty()) {
                m_roomCode.clear();
                emit roomCodeChanged();
              }
              emit errorReceived(obj.value("message").toString());
            } else if (type == "player_joined") {
              emit playerJoined(obj.value("username").toString());
            } else if (type == "joined") {
              emit joinedRoom();
            } else if (type == "start") {
              const qint64 seed =
                  static_cast<qint64>(obj.value("seed").toDouble());
              const qint64 startAt =
                  static_cast<qint64>(obj.value("startAt").toDouble());
              const int duration = obj.value("duration").toInt();
              emit raceStarting(seed, startAt, duration);
            } else if (type == "opponent_left") {
              emit opponentLeft(obj.value("username").toString());
            }

            emit messageReceived(message);
          });
}

bool MultiplayerClient::connected() const { return m_connected; }
QString MultiplayerClient::roomCode() const { return m_roomCode; }

void MultiplayerClient::connectToServer(const QString &url) {
  if (m_connected || m_socket.state() == QAbstractSocket::ConnectingState) {
    qDebug() << "MultiplayerClient: already connected/connecting, skipping";
    return;
  }
  m_roomCode.clear();
  emit roomCodeChanged();
  m_socket.open(QUrl(url));
}

void MultiplayerClient::disconnectFromServer() { m_socket.close(); }

void MultiplayerClient::create(const QString &username) {
  QJsonObject obj;
  obj["type"] = "create";
  obj["username"] = username;

  QJsonDocument doc(obj);
  m_socket.sendTextMessage(
      QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void MultiplayerClient::join(const QString &room, const QString &username) {
  QJsonObject obj;
  obj["type"] = "join";
  obj["room"] = room;
  obj["username"] = username;

  QJsonDocument doc(obj);
  m_socket.sendTextMessage(
      QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void MultiplayerClient::notifyRaceStarted() {
  QJsonObject obj;
  obj["type"] = "race_started";
  QJsonDocument doc(obj);
  m_socket.sendTextMessage(
      QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}
