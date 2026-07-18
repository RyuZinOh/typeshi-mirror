#pragma once
#include <QColor>
#include <QQuickItem>
#include <QTimer>
#include <QVariantList>
#include <QVector>
#include <QtQmlIntegration/qqmlintegration.h>

class ConfettiRenderer : public QQuickItem {
  Q_OBJECT
  QML_NAMED_ELEMENT(ConfettiRenderer)

public:
  explicit ConfettiRenderer(QQuickItem *parent = nullptr);

  Q_INVOKABLE void spawnBurst(const QVariantList &colors);

  struct Particle {
    qreal x, y, vx, vy;
    qreal rotation, rotSpeed;
    qreal age = 0, life;
    qreal size;
    int sides;
    QColor color;
  };

protected:
  QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
  static constexpr int kMaxColorSlots = 4;

  QVector<Particle> m_particles;
  QTimer m_timer;

  void spawnFromOrigin(qreal originX, qreal originY, qreal minAngleDeg,
                       qreal maxAngleDeg, const QVariantList &colors,
                       int count);
  void step();
};
