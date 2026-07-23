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
  Q_PROPERTY(bool isRoomCreator READ isRoomCreator NOTIFY isRoomCreatorChanged)

public:
  explicit MultiplayerClient(QObject *parent = nullptr);

  bool connected() const;
  QString roomCode() const;
  bool isRoomCreator() const;

  Q_INVOKABLE void connectToServer(const QString &url);
  Q_INVOKABLE void disconnectFromServer();
  Q_INVOKABLE void join(const QString &room, const QString &username);
  Q_INVOKABLE void create(const QString &username);
  Q_INVOKABLE void notifyRaceStarted();
  Q_INVOKABLE void sendProgress(double wpm, int charIndex, double accuracy,
                                double consistency, int wordExtraCount);
  Q_INVOKABLE void requestRematch();
  Q_INVOKABLE void acceptRematch();
  Q_INVOKABLE void declineRematch();

signals:
  void connectedChanged();
  void messageReceived(const QString &raw);
  void roomCodeChanged();
  void isRoomCreatorChanged();
  void errorReceived(const QString &message);
  void playerJoined(const QString &username);
  void joinedRoom();
  void raceStarting(qint64 seed, qint64 startAtMs, int duration);
  void opponentLeft(const QString &username);
  void connectionFailed(const QString &message);
  void opponentProgress(const QString &username, double wpm, int charIndex,
                        double accuracy, double consistency,
                        int wordExtraCount);

  void rematchOffered();
  void rematchDeclined();

private:
  QWebSocket m_socket;
  bool m_connected = false;
  bool m_isCreator = false;
  QString m_roomCode;
};
