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
            emit messageReceived(message);
          });
}

bool MultiplayerClient::connected() const { return m_connected; }

void MultiplayerClient::connectToServer(const QString &url) {
  m_socket.open(QUrl(url));
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
