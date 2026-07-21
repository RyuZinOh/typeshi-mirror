#include "./MultiplayerClient.hpp"
#include <QDebug>

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
}

bool MultiplayerClient::connected() const { return m_connected; }

void MultiplayerClient::connectToServer(const QString &url) {
  m_socket.open(QUrl(url));
}
