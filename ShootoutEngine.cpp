#include "./ShootoutEngine.hpp"
#include <QtMath>

ShootoutEngine::ShootoutEngine(QObject *parent) : QObject(parent) {
  m_laneOccupied.assign(kMaxLanes, false);
  m_timer.setInterval(kTickMs);
  connect(&m_timer, &QTimer::timeout, this, &ShootoutEngine::tick);
}

qsizetype ShootoutEngine::wordsCount(QQmlListProperty<FallingWordItem> *prop) {
  auto *self = static_cast<ShootoutEngine *>(prop->object);
  return self->m_words.size();
}

FallingWordItem *ShootoutEngine::wordAt(QQmlListProperty<FallingWordItem> *prop,
                                        qsizetype index) {
  auto *self = static_cast<ShootoutEngine *>(prop->object);
  return self->m_words.at(index);
}

QQmlListProperty<FallingWordItem> ShootoutEngine::words() {
  return QQmlListProperty<FallingWordItem>(
      this, nullptr, &ShootoutEngine::wordsCount, &ShootoutEngine::wordAt);
}

QVariantList ShootoutEngine::bullets() const {
  QVariantList out;
  out.reserve(m_bullets.size());
  for (const auto &b : m_bullets) {
    QVariantMap m;
    m["id"] = b.id;
    m["x"] = b.x;
    m["y"] = b.y;
    out.append(m);
  }
  return out;
}

void ShootoutEngine::setPaused(bool paused) {
  if (paused == m_paused)
    return;
  m_paused = paused;
  emit pausedChanged();
}

qreal ShootoutEngine::shipX() const { return m_shipX; }
int ShootoutEngine::laneCount() const { return m_laneCount; }
bool ShootoutEngine::paused() const { return m_paused; }

void ShootoutEngine::setLaneCount(int count) {
  count = qBound(1, count, kMaxLanes);
  if (count == m_laneCount) {
    return;
  }
  m_laneCount = count;
  emit laneCountChanged();
}

void ShootoutEngine::setViewportSize(qreal width, qreal height) {
  m_viewportWidth = width;
  m_viewportHeight = height;
  m_shipX = width / 2.0;
  emit shipXChanged();
}

qreal ShootoutEngine::laneCenterX(int lane) const {
  if (m_laneCount <= 0 || m_viewportWidth <= 0) {
    return m_viewportWidth / 2.0;
  }
  const qreal margin = 60.0;
  const qreal effectiveWidth = qMin(m_viewportWidth, 1880.0);
  const qreal usable = qMax(0.0, effectiveWidth - margin * 2);
  const qreal slot = usable / m_laneCount;
  return margin + slot * (lane + 0.5);
}

int ShootoutEngine::firstFreeLane() const {
  for (int i = 0; i < m_laneCount; ++i) {
    if (!m_laneOccupied.at(i)) {
      return i;
    }
  }
  return -1;
}

FallingWordItem *ShootoutEngine::findByWordStart(int wordStart) const {
  for (auto *w : m_words) {
    if (w->wordStart() == wordStart) {
      return w;
    }
  }
  return nullptr;
}

void ShootoutEngine::start(qreal viewportWidth, qreal viewportHeight) {
  qDeleteAll(m_words);
  m_words.clear();
  m_bullets.clear();
  m_laneOccupied.assign(kMaxLanes, false);
  m_nextWordId = 0;
  m_nextBulletId = 0;
  setViewportSize(viewportWidth, viewportHeight);
  emit wordsStructureChanged();
  emit bulletsChanged();

  m_clock.start();
  m_lastTickMs = 0;
  m_timer.start();
}

void ShootoutEngine::stop() {
  m_timer.stop();
  qDeleteAll(m_words);
  m_words.clear();
  m_bullets.clear();
  m_laneOccupied.assign(kMaxLanes, false);
  emit wordsStructureChanged();
  emit bulletsChanged();
}

void ShootoutEngine::spawnWord(int wordStart, int wordEnd) {
  const int lane = firstFreeLane();
  if (lane < 0) {
    return;
  }

  m_laneOccupied[lane] = true;

  auto *w = new FallingWordItem(m_nextWordId++, lane, wordStart, wordEnd,
                                laneCenterX(lane), -40.0 - (lane * 30.0), this);
  m_words.append(w);
  emit wordsStructureChanged();
}

void ShootoutEngine::markWordDying(int wordStart) {
  FallingWordItem *w = findByWordStart(wordStart);
  if (w && !w->dying()) {
    w->setDying(true);
  }
}

int ShootoutEngine::laneXFor(int wordStart) const {
  for (auto *w : m_words) {
    if (wordStart >= w->wordStart() && wordStart < w->wordEnd()) {
      return static_cast<int>(w->x());
    }
  }
  return static_cast<int>(m_viewportWidth / 2.0);
}

void ShootoutEngine::fireBullet(int, qreal targetX, qreal targetY,
                                const QString &ch, qreal originX,
                                qreal originY) {
  Bullet b;
  b.id = m_nextBulletId++;
  b.startX = originX;
  b.startY = originY;
  b.x = originX;
  b.y = originY;
  b.targetX = targetX;
  b.targetY = targetY;
  b.ch = ch;
  b.progress = 0.0;

  m_bullets.append(b);
  emit bulletsChanged();
}

void ShootoutEngine::tick() {
  const qint64 nowMs = m_clock.elapsed();
  const qreal dt =
      m_lastTickMs > 0 ? (nowMs - m_lastTickMs) / 1000.0 : kTickMs / 1000.0;
  m_lastTickMs = nowMs;

  bool structuralChange = false;
  for (int i = m_words.size() - 1; i >= 0; --i) {
    FallingWordItem *w = m_words[i];
    if (!w->dying()) {
      w->setY(w->y() + kFallSpeed * dt);
    }
    const bool missed = !w->dying() && w->y() > m_viewportHeight - 40;
    if (missed || w->dying()) {
      const int wordStart = w->wordStart();
      m_laneOccupied[w->lane()] = false;
      m_words.remove(i);
      w->deleteLater();
      structuralChange = true;
      if (missed) {
        emit wordMissed(wordStart);
      }
    }
  }
  if (structuralChange) {
    emit wordsStructureChanged();
  }

  bool bulletsDirty = false;
  for (int i = m_bullets.size() - 1; i >= 0; --i) {
    Bullet &b = m_bullets[i];
    const qreal distance =
        qMax(1.0, qAbs(b.targetX - b.startX) + qAbs(b.targetY - b.startY));
    b.progress += (kBulletSpeed * dt) / distance;
    b.x = b.startX + (b.targetX - b.startX) * b.progress;
    b.y = b.startY + (b.targetY - b.startY) * b.progress;

    if (b.progress >= 1.0) {
      emit letterImpact(b.ch, b.targetX, b.targetY);
      m_bullets.remove(i);
    }
    bulletsDirty = true;
  }
  if (bulletsDirty) {
    emit bulletsChanged();
  }
}
