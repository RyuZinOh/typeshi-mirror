#include "./ConfettiRenderer.hpp"
#include <QRandomGenerator>
#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QtMath>

namespace {
void appendParticle(QSGGeometry::Point2D *vertices, int &idx,
                    const ConfettiRenderer::Particle &p, qreal shrink) {
  const qreal halfSize = (p.size * shrink) / 2.0;
  const qreal rot = qDegreesToRadians(p.rotation);

  for (int s = 0; s < p.sides; ++s) {
    const qreal a0 = rot + (2 * M_PI * s) / p.sides;
    const qreal a1 = rot + (2 * M_PI * (s + 1)) / p.sides;

    vertices[idx++].set(p.x, p.y);
    vertices[idx++].set(p.x + halfSize * qCos(a0), p.y + halfSize * qSin(a0));
    vertices[idx++].set(p.x + halfSize * qCos(a1), p.y + halfSize * qSin(a1));
  }
}
} // namespace

ConfettiRenderer::ConfettiRenderer(QQuickItem *parent) : QQuickItem(parent) {
  setFlag(ItemHasContents, true);
  m_timer.setInterval(16);
  connect(&m_timer, &QTimer::timeout, this, &ConfettiRenderer::step);
}

void ConfettiRenderer::spawnFromOrigin(qreal originX, qreal originY,
                                       qreal minAngleDeg, qreal maxAngleDeg,
                                       const QVariantList &colors, int count) {
  auto *rng = QRandomGenerator::global();

  for (int i = 0; i < count; ++i) {
    Particle p;
    const qreal angleDeg =
        minAngleDeg + rng->bounded(maxAngleDeg - minAngleDeg);
    const qreal rad = qDegreesToRadians(angleDeg);
    const qreal speed = 650.0 + rng->bounded(650.0);

    p.x = originX;
    p.y = originY;
    p.vx = qCos(rad) * speed;
    p.vy = qSin(rad) * speed;
    p.rotation = rng->bounded(360.0);
    p.rotSpeed = (rng->generateDouble() - 0.5) * 540.0;
    p.life = 2.2 + rng->generateDouble() * 0.8;
    p.size = 4.0 + rng->generateDouble() * 4.0;
    p.sides = rng->generateDouble() > 0.5 ? 10 : 4;
    p.color = colors.at(i % colors.size()).value<QColor>();

    m_particles.append(p);
  }
}
void ConfettiRenderer::spawnBurst(const QVariantList &colors) {
  if (colors.isEmpty()) {
    return;
  }

  const qreal originY = height() / 2.0 + 200;

  spawnFromOrigin(0, originY, -75.0, -15.0, colors, 90);

  spawnFromOrigin(width(), originY, -165.0, -105.0, colors, 90);

  if (!m_timer.isActive()) {
    m_timer.start();
  }
}

void ConfettiRenderer::step() {
  const qreal dt = 0.016;
  const qreal g = 650.0;

  int writeIdx = 0;
  for (int i = 0; i < m_particles.size(); ++i) {
    Particle p = m_particles.at(i);
    p.vy += g * dt;
    p.x += p.vx * dt;
    p.y += p.vy * dt;
    p.rotation += p.rotSpeed * dt;
    p.age += dt;

    if (p.y > height() + 40 || p.age > p.life) {
      continue;
    }
    m_particles[writeIdx++] = p;
  }
  m_particles.resize(writeIdx);

  if (m_particles.isEmpty()) {
    m_timer.stop();
  }
  update();
}

QSGNode *ConfettiRenderer::updatePaintNode(QSGNode *oldNode,
                                           UpdatePaintNodeData *) {
  QSGNode *root = oldNode;
  if (!root) {
    root = new QSGNode();
    for (int c = 0; c < kMaxColorSlots; ++c) {
      auto *node = new QSGGeometryNode();
      auto *geometry =
          new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 0);
      geometry->setDrawingMode(QSGGeometry::DrawTriangles);
      node->setGeometry(geometry);
      node->setFlag(QSGNode::OwnsGeometry);
      node->setMaterial(new QSGFlatColorMaterial());
      node->setFlag(QSGNode::OwnsMaterial);
      root->appendChildNode(node);
    }
  }

  QVector<QColor> slotColors;
  QVector<QVector<Particle>> slotParticles(kMaxColorSlots);

  for (const Particle &p : m_particles) {
    int slot = slotColors.indexOf(p.color);
    if (slot < 0) {
      if (slotColors.size() >= kMaxColorSlots) {
        slot = 0;
      } else {
        slot = slotColors.size();
        slotColors.append(p.color);
      }
    }
    slotParticles[slot].append(p);
  }

  QSGNode *child = root->firstChild();
  for (int c = 0; c < kMaxColorSlots && child;
       ++c, child = child->nextSibling()) {
    auto *node = static_cast<QSGGeometryNode *>(child);
    const auto &particles = slotParticles.at(c);

    int vertexCount = 0;
    for (const Particle &p : particles) {
      vertexCount += p.sides * 3;
    }

    QSGGeometry *geometry = node->geometry();
    geometry->allocate(vertexCount);
    auto *vertices = geometry->vertexDataAsPoint2D();

    int idx = 0;
    for (const Particle &p : particles) {
      qreal shrink = 1.0;
      const qreal lifeT = p.age / p.life;
      if (lifeT > 0.7) {
        shrink = qMax(0.0, 1.0 - (lifeT - 0.7) / 0.3);
      }
      appendParticle(vertices, idx, p, shrink);
    }

    node->markDirty(QSGNode::DirtyGeometry);

    if (!particles.isEmpty()) {
      auto *material = static_cast<QSGFlatColorMaterial *>(node->material());
      material->setColor(slotColors.at(c));
      node->markDirty(QSGNode::DirtyMaterial);
    }
  }

  return root;
}
