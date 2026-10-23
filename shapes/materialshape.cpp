#include "./materialshape.hpp"
#include "../Core/paintutil.hpp"
#include <QPainter>
#include <QPen>
#include <QQmlEngine>
#include <QQuickWindow>
#include <algorithm>
#include <cmath>

namespace {

static_assert(MaterialShape::Heart + 1 == Morph::kShapeCount,
              "table must match MaterialShape::Type");

constexpr qreal kOvershootGain = 0.5;
constexpr qreal kFill = 0.9;
constexpr qreal kRotStiffness = 90.0;
constexpr qreal kRotDamping = 0.6;
constexpr qreal kImageBleed = 1.15;
constexpr qreal kLoadBleed = 1.45;

constexpr std::array<MaterialShape::Type, 7> kDefaultLoading = {
    MaterialShape::SoftBurst, MaterialShape::Cookie9Sided,
    MaterialShape::Pentagon,  MaterialShape::Pill,
    MaterialShape::Sunny,     MaterialShape::Cookie4Sided,
    MaterialShape::Oval};

} // namespace

MaterialShape::MaterialShape(QQuickItem *parent) : QQuickPaintedItem(parent) {
  setAntialiasing(true);
  m_current = Morph::baseCubics(int(m_shape));

  m_border = new MaterialShapeBorder(this);
  connect(m_border, &MaterialShapeBorder::widthChanged, this, [this] {
    m_pathDirty = true;
    m_imageDirty = true;
    update();
  });
  connect(m_border, &MaterialShapeBorder::colorChanged, this,
          [this] { update(); });

  m_driver = new Ryu::SpringDriver(this);
  m_driver->tick = [this](qreal dt) { tick(dt); };

  m_loadTimer = new QTimer(this);
  m_loadTimer->setSingleShot(true);
  connect(m_loadTimer, &QTimer::timeout, this, &MaterialShape::advanceLoading);
}

void MaterialShape::componentComplete() {
  QQuickPaintedItem::componentComplete();
  if (m_loading)
    startLoading();
}

void MaterialShape::setShape(Type t) {
  if (m_shape == t || int(t) < 0 || int(t) >= Morph::kShapeCount)
    return;
  if (!m_animated || !isComponentComplete() || !isVisible() || !window())
    snapTo(t);
  else
    startMorph(t);
}

void MaterialShape::ensureDriver() {
  if (m_driver->state() != QAbstractAnimation::Running)
    m_driver->start();
}

void MaterialShape::snapTo(Type t) {
  m_shape = t;
  m_current = Morph::baseCubics(int(t));
  m_from.clear();
  m_to.clear();
  m_morph = Ryu::Spring{1.0, 0.0, 1.0};
  m_pathDirty = true;
  setMorphing(false);
  emit shapeChanged();
  update();
  if (m_loading)
    scheduleNext();
}

void MaterialShape::startMorph(Type t) {
  const bool wasMorphing = m_morphing;

  if (!wasMorphing) {
    const Morph::AlignedPair &p = Morph::alignedPair(int(m_shape), int(t));
    m_from = p.from;
    m_to = p.to;
  } else {
    m_from = m_current;
    m_to = Morph::baseCubics(int(t));
    Morph::alignCubics(m_from, m_to);
  }

  m_shape = t;
  m_morph = Ryu::Spring{0.0, wasMorphing ? std::max(m_morph.v, 0.0) : 0.0, 1.0};
  emit shapeChanged();

  setMorphing(true);
  applyProgress(0.0);
  ensureDriver();
}

void MaterialShape::tick(qreal dt) {
  if (m_morphing)
    stepMorph(dt);
  const bool rotActive = stepRotation(dt);
  if (!m_morphing && !rotActive)
    m_driver->stop();
}

void MaterialShape::stepMorph(qreal dt) {
  if (dt <= 0.0)
    return;
  if (!Ryu::stepSpring(m_morph, m_stiffness, m_damping, dt, 0.0005)) {
    finishMorph();
    return;
  }
  applyProgress(m_morph.x);
}

bool MaterialShape::stepRotation(qreal dt) {
  if (dt <= 0.0)
    return true;

  if (Ryu::stepSpring(m_rot, kRotStiffness, kRotDamping, dt, 0.02)) {
    setRotation(m_rot.x);
    if (m_loading && (!m_image.isNull() || !m_glyph.isEmpty()))
      update();
    return true;
  }

  if (std::abs(m_rot.x) >= 720.0) {
    const qreal base = 360.0 * std::floor(m_rot.x / 360.0);
    m_rot.x -= base;
    m_rot.t -= base;
  }
  setRotation(m_rot.x);
  update();
  return false;
}

void MaterialShape::applyProgress(qreal p) {
  const qreal t = p > 1.0 ? 1.0 + (p - 1.0) * kOvershootGain : p;
  const int n = std::min(m_from.size(), m_to.size());
  m_current.resize(n);
  for (int i = 0; i < n; ++i) {
    const MorphCubic &a = m_from[i];
    const MorphCubic &b = m_to[i];
    MorphCubic &c = m_current[i];
    for (int j = 0; j < 4; ++j)
      c[j] = a[j] + (b[j] - a[j]) * t;
  }
  m_pathDirty = true;
  update();
}

void MaterialShape::finishMorph() {
  m_current = Morph::baseCubics(int(m_shape));
  m_from.clear();
  m_to.clear();
  m_morph = Ryu::Spring{1.0, 0.0, 1.0};
  m_pathDirty = true;
  setMorphing(false);
  update();
  if (m_loading)
    scheduleNext();
}

void MaterialShape::setMorphing(bool v) {
  if (m_morphing == v)
    return;
  m_morphing = v;
  emit morphingChanged();
}

int MaterialShape::loadCount() const {
  if (m_loadAll)
    return Morph::kShapeCount;
  return m_loadSeq.isEmpty() ? int(kDefaultLoading.size()) : m_loadSeq.size();
}

MaterialShape::Type MaterialShape::loadShapeAt(int i) const {
  if (m_loadAll)
    return Type(i);
  if (m_loadSeq.isEmpty())
    return kDefaultLoading[i];
  return Type(m_loadSeq[i]);
}

void MaterialShape::setLoading(bool v) {
  if (m_loading == v)
    return;
  m_loading = v;
  m_imageDirty = true;
  emit loadingChanged();
  if (v) {
    if (isComponentComplete())
      startLoading();
  } else {
    m_loadTimer->stop();
  }
  update();
}

void MaterialShape::setLoadingGap(int ms) {
  ms = std::max(0, ms);
  if (m_loadGap == ms)
    return;
  m_loadGap = ms;
  emit loadingGapChanged();
}

void MaterialShape::setLoadingKick(qreal deg) {
  if (qFuzzyCompare(m_loadKick, deg))
    return;
  m_loadKick = deg;
  emit loadingKickChanged();
}

void MaterialShape::setContained(bool v) {
  if (m_contained == v)
    return;
  m_contained = v;
  m_pathDirty = true;
  m_imageDirty = true;
  emit containedChanged();
  update();
}

void MaterialShape::setContainerColor(const QColor &v) {
  if (m_containerColor == v)
    return;
  m_containerColor = v;
  emit containerColorChanged();
  update();
}

void MaterialShape::setContainedScale(qreal v) {
  v = std::clamp(v, 0.1, 1.0);
  if (qFuzzyCompare(m_containedScale, v))
    return;
  m_containedScale = v;
  m_pathDirty = true;
  m_imageDirty = true;
  emit containedScaleChanged();
  update();
}

void MaterialShape::setLoadingAllShapes(bool v) {
  if (m_loadAll == v)
    return;
  m_loadAll = v;
  emit loadingAllShapesChanged();
}

void MaterialShape::setLoadingSequence(const QList<int> &seq) {
  QList<int> clean;
  clean.reserve(seq.size());
  for (int s : seq)
    if (s >= 0 && s < Morph::kShapeCount)
      clean.append(s);
  if (m_loadSeq == clean)
    return;
  m_loadSeq = clean;
  emit loadingSequenceChanged();
}

void MaterialShape::startLoading() {
  m_rot = Ryu::Spring{rotation(), 0.0, rotation()};
  m_loadIndex = loadCount() - 1;
  advanceLoading();
}

void MaterialShape::advanceLoading() {
  if (!m_loading)
    return;

  m_loadIndex = (m_loadIndex + 1) % loadCount();
  m_rot.t += m_loadKick;
  ensureDriver();

  const Type next = loadShapeAt(m_loadIndex);
  if (next == m_shape) {
    if (!m_morphing)
      scheduleNext();
    return;
  }
  setShape(next);
}

void MaterialShape::scheduleNext() {
  if (!m_loading || !isComponentComplete() || !isVisible() || !window())
    return;
  m_loadTimer->start(m_loadGap);
}

void MaterialShape::setSource(const QUrl &u) {
  if (m_source == u)
    return;
  m_source = u;
  m_image = QImage();
  m_scaled = QImage();
  if (u.isValid() && !u.isEmpty()) {
    const QString path = Ryu::resolveUrl(qmlContext(this), u);
    if (path.isEmpty() || !m_image.load(path))
      qWarning("MaterialShape: failed to load image '%s' (resolved: '%s')",
               qPrintable(u.toString()), qPrintable(path));
  }
  m_imageDirty = true;
  emit sourceChanged();
  update();
}

void MaterialShape::setFillMode(FillMode m) {
  if (m_fillMode == m)
    return;
  m_fillMode = m;
  m_imageDirty = true;
  emit fillModeChanged();
  update();
}

void MaterialShape::setGlyph(const QString &v) {
  if (m_glyph == v)
    return;
  m_glyph = v;
  emit glyphChanged();
  update();
}

void MaterialShape::setGlyphFont(const QFont &v) {
  if (m_glyphFont == v)
    return;
  m_glyphFont = v;
  emit glyphFontChanged();
  update();
}

void MaterialShape::setGlyphColor(const QColor &v) {
  if (m_glyphColor == v)
    return;
  m_glyphColor = v;
  emit glyphColorChanged();
  update();
}

void MaterialShape::setGlyphSize(qreal v) {
  v = std::max(0.0, v);
  if (qFuzzyCompare(m_glyphSize, v))
    return;
  m_glyphSize = v;
  emit glyphSizeChanged();
  update();
}

void MaterialShape::buildImage() {
  m_imageDirty = false;
  m_scaled = QImage();
  if (m_image.isNull())
    return;

  const qreal dpr = window() ? window()->devicePixelRatio() : 1.0;
  const qreal bleed = m_loading ? kLoadBleed : kImageBleed;
  const qreal bw = m_border->width();
  const qreal side = std::min(width() - bw, height() - bw) * kFill * bleed *
                     (m_contained ? m_containedScale : 1.0);
  const int px = qRound(side * dpr);
  if (px <= 0)
    return;

  const qreal iw = m_image.width();
  const qreal ih = m_image.height();
  QRectF src(0, 0, iw, ih);
  QRectF dst(0, 0, px, px);

  if (m_fillMode == Crop) {
    const qreal s = std::min(iw, ih);
    src = QRectF((iw - s) / 2.0, (ih - s) / 2.0, s, s);
  } else if (m_fillMode == Fit) {
    const qreal k = px / std::max(iw, ih);
    const qreal dw = iw * k;
    const qreal dh = ih * k;
    dst = QRectF((px - dw) / 2.0, (px - dh) / 2.0, dw, dh);
  }

  QImage out(px, px, QImage::Format_ARGB32_Premultiplied);
  out.fill(Qt::transparent);
  QPainter q(&out);
  q.setRenderHint(QPainter::SmoothPixmapTransform, true);
  q.drawImage(dst, m_image, src);
  q.end();
  out.setDevicePixelRatio(dpr);
  m_scaled = std::move(out);
}

void MaterialShape::setColor(const QColor &c) {
  if (m_color == c)
    return;
  m_color = c;
  emit colorChanged();
  update();
}

void MaterialShape::setAnimated(bool v) {
  if (m_animated == v)
    return;
  m_animated = v;
  if (!v && m_morphing)
    finishMorph();
  emit animatedChanged();
}

void MaterialShape::setSpringStiffness(qreal v) {
  v = std::max(1.0, v);
  if (qFuzzyCompare(m_stiffness, v))
    return;
  m_stiffness = v;
  emit springStiffnessChanged();
}

void MaterialShape::setSpringDamping(qreal v) {
  v = qBound(0.05, v, 2.0);
  if (qFuzzyCompare(m_damping, v))
    return;
  m_damping = v;
  emit springDampingChanged();
}

void MaterialShape::geometryChange(const QRectF &newGeometry,
                                   const QRectF &oldGeometry) {
  QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
  if (newGeometry.size() != oldGeometry.size()) {
    m_pathDirty = true;
    m_imageDirty = true;
  }
}

void MaterialShape::itemChange(ItemChange change, const ItemChangeData &data) {
  QQuickPaintedItem::itemChange(change, data);

  const bool gone = (change == ItemVisibleHasChanged && !data.boolValue) ||
                    (change == ItemSceneChange && !data.window);
  const bool back = (change == ItemVisibleHasChanged && data.boolValue) ||
                    (change == ItemSceneChange && data.window);

  if (gone) {
    if (m_morphing)
      finishMorph();
    m_loadTimer->stop();
  } else if (back && m_loading && !m_morphing) {
    scheduleNext();
  }

  if (change == ItemSceneChange && data.window)
    m_imageDirty = true;
}

void MaterialShape::rebuildPath() {
  m_pathDirty = false;
  m_path = QPainterPath();
  if (m_current.isEmpty())
    return;

  const qreal inset = m_border->width() / 2.0;
  const QRectF dst =
      QRectF(0, 0, width(), height()).adjusted(inset, inset, -inset, -inset);
  if (dst.isEmpty())
    return;

  const qreal s = std::min(dst.width(), dst.height()) * kFill *
                  (m_contained ? m_containedScale : 1.0);
  const QPointF c = dst.center();
  auto map = [&](const QPointF &p) {
    return QPointF(c.x() + p.x() * s, c.y() + p.y() * s);
  };

  m_path.reserve(m_current.size() * 3 + 2);
  m_path.setFillRule(Qt::WindingFill);
  m_path.moveTo(map(m_current[0][0]));
  for (const MorphCubic &cb : std::as_const(m_current))
    m_path.cubicTo(map(cb[1]), map(cb[2]), map(cb[3]));
  m_path.closeSubpath();
}

void MaterialShape::paint(QPainter *p) {
  if (m_pathDirty)
    rebuildPath();
  if (m_path.isEmpty())
    return;

  p->setRenderHint(QPainter::Antialiasing, true);
  p->setPen(Qt::NoPen);
  if (m_contained && m_containerColor.alpha() > 0) {
    const qreal d = std::min(width(), height()) - m_border->width();
    if (d > 0.0) {
      p->setBrush(m_containerColor);
      p->drawEllipse(QPointF(width() / 2.0, height() / 2.0), d / 2.0, d / 2.0);
    }
  }
  p->setBrush(m_color);
  p->drawPath(m_path);

  if (!m_image.isNull()) {
    if (m_imageDirty)
      buildImage();
    if (!m_scaled.isNull()) {
      const QSizeF sz = m_scaled.deviceIndependentSize();
      p->save();
      p->setClipPath(m_path);
      p->setRenderHint(QPainter::SmoothPixmapTransform, true);
      p->translate(width() / 2.0, height() / 2.0);
      if (m_loading)
        p->rotate(-rotation());
      p->drawImage(QPointF(-sz.width() / 2.0, -sz.height() / 2.0), m_scaled);
      p->restore();
    }
  }

  if (!m_glyph.isEmpty() && m_glyphSize > 0.0) {
    p->save();
    p->setClipPath(m_path);
    p->translate(width() / 2.0, height() / 2.0);
    if (m_loading)
      p->rotate(-rotation());
    Ryu::drawGlyph(p, m_glyphFont, m_glyph, QPointF(0.0, 0.0), m_glyphSize,
                   m_glyphColor);
    p->restore();
  }

  const qreal bw = m_border->width();
  const QColor bc = m_border->color();
  if (bw > 0.0 && bc.alpha() > 0) {
    p->setBrush(Qt::NoBrush);
    p->setPen(QPen(bc, bw, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    if (m_contained) {
      const qreal d = std::min(width(), height()) - bw;
      p->drawEllipse(QPointF(width() / 2.0, height() / 2.0), d / 2.0, d / 2.0);
    } else {
      p->drawPath(m_path);
    }
  }
}
