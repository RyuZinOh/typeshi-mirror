#pragma once
#include <QObject>
#include <QWebSocket>
#include <QtQmlIntegration/qqmlintegration.h>

class MultiplayerClient : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Multiplayer)
  QML_SINGLETON

  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
  Q_PROPERTY(QString roomCode READ roomCode NOTIFY roomCodeChanged)

public:
  explicit MultiplayerClient(QObject *parent = nullptr);

  bool connected() const;
  QString roomCode() const;

  Q_INVOKABLE void connectToServer(const QString &url);
  Q_INVOKABLE void join(const QString &room, const QString &username);
  Q_INVOKABLE void create(const QString &username);

signals:
  void connectedChanged();
  void messageReceived(const QString &raw);
  void roomCodeChanged();
  void errorReceived(const QString &message);
  void playerJoined(const QString &username);
  void joinedRoom();

private:
  QWebSocket m_socket;
  bool m_connected = false;
  QString m_roomCode;
};
