#pragma once
#include <QElapsedTimer>
#include <QObject>
#include <QQmlListProperty>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVector>
#include <QtQmlIntegration/qqmlintegration.h>

class FallingWordItem : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_UNCREATABLE("FallingWordItem is created internally by Shootout")

  Q_PROPERTY(int wordStart READ wordStart CONSTANT)
  Q_PROPERTY(int wordEnd READ wordEnd CONSTANT)
  Q_PROPERTY(qreal x READ x CONSTANT)
  Q_PROPERTY(qreal y READ y NOTIFY yChanged)
  Q_PROPERTY(bool dying READ dying NOTIFY dyingChanged)

public:
  explicit FallingWordItem(int id, int lane, int wordStart, int wordEnd,
                           qreal x, qreal y, QObject *parent = nullptr)
      : QObject(parent), m_id(id), m_lane(lane), m_wordStart(wordStart),
        m_wordEnd(wordEnd), m_x(x), m_y(y) {}

  int id() const { return m_id; }
  int lane() const { return m_lane; }
  int wordStart() const { return m_wordStart; }
  int wordEnd() const { return m_wordEnd; }
  qreal x() const { return m_x; }
  qreal y() const { return m_y; }
  bool dying() const { return m_dying; }

  void setY(qreal y) {
    if (qFuzzyCompare(m_y, y)) {
      return;
    }
    m_y = y;
    emit yChanged();
  }

  void setDying(bool dying) {
    if (m_dying == dying) {
      return;
    }
    m_dying = dying;
    emit dyingChanged();
  }

signals:
  void yChanged();
  void dyingChanged();

private:
  int m_id;
  int m_lane;
  int m_wordStart;
  int m_wordEnd;
  qreal m_x;
  qreal m_y;
  bool m_dying = false;
};

class ShootoutEngine : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Shootout)
  QML_SINGLETON

  Q_PROPERTY(QQmlListProperty<FallingWordItem> words READ words NOTIFY
                 wordsStructureChanged)
  Q_PROPERTY(QVariantList bullets READ bullets NOTIFY bulletsChanged)
  Q_PROPERTY(qreal shipX READ shipX NOTIFY shipXChanged)
  Q_PROPERTY(
      int laneCount READ laneCount WRITE setLaneCount NOTIFY laneCountChanged)
  Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)

public:
  explicit ShootoutEngine(QObject *parent = nullptr);

  QQmlListProperty<FallingWordItem> words();
  QVariantList bullets() const;
  qreal shipX() const;
  int laneCount() const;
  void setLaneCount(int count);
  bool paused() const;

  Q_INVOKABLE void start(qreal viewportWidth, qreal viewportHeight);
  Q_INVOKABLE void stop();
  Q_INVOKABLE void setViewportSize(qreal width, qreal height);
  Q_INVOKABLE void spawnWord(int wordStart, int wordEnd);
  Q_INVOKABLE void markWordDying(int wordStart);
  Q_INVOKABLE int laneXFor(int wordStart) const;
  Q_INVOKABLE void fireBullet(int globalIndex, qreal targetX, qreal targetY,
                              const QString &ch, qreal originX, qreal originY);
  Q_INVOKABLE void setPaused(bool paused);

signals:
  void wordsStructureChanged();
  void bulletsChanged();
  void shipXChanged();
  void laneCountChanged();
  void letterImpact(QString ch, qreal x, qreal y);
  void pausedChanged();
  void wordMissed(int wordStart);

private:
  struct Bullet {
    int id;
    qreal startX;
    qreal startY;
    qreal x;
    qreal y;
    qreal targetX;
    qreal targetY;
    QString ch;
    qreal progress;
  };

  static constexpr int kMaxLanes = 8;
  static constexpr qreal kFallSpeed = 150.0;
  static constexpr qreal kBulletSpeed = 8000.0;
  static constexpr int kTickMs = 16;

  QTimer m_timer;
  QElapsedTimer m_clock;
  qint64 m_lastTickMs = 0;

  qreal m_viewportWidth = 0;
  qreal m_viewportHeight = 0;
  int m_laneCount = 5;
  bool m_paused = false;

  QVector<FallingWordItem *> m_words;
  QVector<Bullet> m_bullets;
  QVector<bool> m_laneOccupied;

  int m_nextWordId = 0;
  int m_nextBulletId = 0;
  qreal m_shipX = 0;

  void tick();
  qreal laneCenterX(int lane) const;
  int firstFreeLane() const;
  FallingWordItem *findByWordStart(int wordStart) const;

  static qsizetype wordsCount(QQmlListProperty<FallingWordItem> *prop);
  static FallingWordItem *wordAt(QQmlListProperty<FallingWordItem> *prop,
                                 qsizetype index);
};
