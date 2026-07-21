#pragma once
#include <QObject>
#include <QWebSocket>
#include <QtQmlIntegration/qqmlintegration.h>

class MultiplayerClient : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Multiplayer)
  QML_SINGLETON

  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
  explicit MultiplayerClient(QObject *parent = nullptr);

  bool connected() const;

  Q_INVOKABLE void connectToServer(const QString &url);

signals:
  void connectedChanged();

private:
  QWebSocket m_socket;
  bool m_connected = false;
};
