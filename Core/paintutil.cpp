#include "./paintutil.hpp"
#include <QDir>
#include <QFileInfo>
#include <QFontMetricsF>
#include <QImageReader>
#include <QPen>
#include <QQmlContext>
#include <QQmlFile>
#include <algorithm>

namespace Ryu {

QColor mix(const QColor &a, const QColor &b, qreal t) {
  t = std::clamp(t, 0.0, 1.0);
  return QColor::fromRgbF(a.redF() + (b.redF() - a.redF()) * t,
                          a.greenF() + (b.greenF() - a.greenF()) * t,
                          a.blueF() + (b.blueF() - a.blueF()) * t,
                          a.alphaF() + (b.alphaF() - a.alphaF()) * t);
}

QPainterPath roundedRect(const QRectF &r, qreal tl, qreal tr, qreal br,
                         qreal bl) {
  const qreal maxR = std::min(r.height(), r.width()) / 2.0;
  tl = std::clamp(tl, 0.0, maxR);
  tr = std::clamp(tr, 0.0, maxR);
  br = std::clamp(br, 0.0, maxR);
  bl = std::clamp(bl, 0.0, maxR);
  const qreal x0 = r.left(), x1 = r.right(), t = r.top(), b = r.bottom();

  QPainterPath p;
  p.moveTo(x0 + tl, t);
  p.lineTo(x1 - tr, t);
  if (tr > 0.0)
    p.arcTo(x1 - 2 * tr, t, 2 * tr, 2 * tr, 90, -90);
  p.lineTo(x1, b - br);
  if (br > 0.0)
    p.arcTo(x1 - 2 * br, b - 2 * br, 2 * br, 2 * br, 0, -90);
  p.lineTo(x0 + bl, b);
  if (bl > 0.0)
    p.arcTo(x0, b - 2 * bl, 2 * bl, 2 * bl, 270, -90);
  p.lineTo(x0, t + tl);
  if (tl > 0.0)
    p.arcTo(x0, t, 2 * tl, 2 * tl, 180, -90);
  p.closeSubpath();
  return p;
}

QFont styledFont(const QFont &base, qreal px, int weight) {
  QFont f = base;
  f.setPixelSize(qMax(1, qRound(px)));
  f.setWeight(QFont::Weight(weight));
  f.setHintingPreference(QFont::PreferNoHinting);
  f.setStyleStrategy(
      QFont::StyleStrategy(QFont::PreferAntialias | QFont::PreferQuality));
  return f;
}

void drawGlyph(QPainter *p, const QFont &font, const QString &text,
               const QPointF &center, qreal size, const QColor &color) {
  QFont f = font;
  f.setPixelSize(qMax(1, qRound(size)));
  f.setHintingPreference(QFont::PreferNoHinting);

  QPainterPath gp;
  gp.addText(QPointF(0.0, 0.0), f, text);
  const QRectF br = gp.boundingRect();
  if (br.isEmpty())
    return;

  const qreal k = std::min(1.0, size / std::max(br.width(), br.height()));
  p->save();
  p->translate(center);
  p->scale(k, k);
  p->translate(-br.center());
  p->setPen(Qt::NoPen);
  p->setBrush(color);
  p->drawPath(gp);
  p->restore();
}

void drawLabel(QPainter *p, const QFont &font, const QString &text, qreal x,
               qreal cy, const QColor &color) {
  if (text.isEmpty())
    return;
  const QFontMetricsF fm(font);
  QPainterPath tp;
  tp.addText(QPointF(0.0, 0.0), font, text);
  p->save();
  p->translate(x, cy + (fm.ascent() - fm.descent()) / 2.0);
  p->setPen(Qt::NoPen);
  p->setBrush(color);
  p->drawPath(tp);
  p->restore();
}

void strokeInside(QPainter *p, const QPainterPath &path, const QColor &color,
                  qreal width) {
  p->save();
  p->setClipPath(path);
  p->setBrush(Qt::NoBrush);
  p->setPen(
      QPen(color, width * 2.0, Qt::SolidLine, Qt::FlatCap, Qt::RoundJoin));
  p->drawPath(path);
  p->restore();
  p->setPen(Qt::NoPen);
}

QString resolveUrl(const QQmlContext *ctx, const QUrl &u) {
  if (u.isLocalFile() || u.scheme().compare("qrc", Qt::CaseInsensitive) == 0)
    return QQmlFile::urlToLocalFileOrQrc(u);

  if (!u.scheme().isEmpty() && u.scheme().size() != 1)
    return {};

  QString p = u.toString();
  if (p.startsWith(QLatin1String("~/")))
    p = QDir::homePath() + p.mid(1);

  if (QDir::isAbsolutePath(p))
    return p;

  if (ctx) {
    const QString local =
        QQmlFile::urlToLocalFileOrQrc(ctx->resolvedUrl(QUrl(p)));
    if (!local.isEmpty() &&
        (local.startsWith(QLatin1Char(':')) || QFileInfo::exists(local)))
      return local;
  }

  return QFileInfo(p).absoluteFilePath();
}

QImage loadTinted(const QString &path, qreal size, qreal dpr,
                  const QColor &color) {
  const int px = qRound(size * dpr);
  if (px <= 0 || path.isEmpty())
    return {};

  QImageReader r(path);
  QSize s = r.size();
  if (s.isValid()) {
    s.scale(px, px, Qt::KeepAspectRatio);
    r.setScaledSize(s);
  }
  const QImage in = r.read();
  if (in.isNull()) {
    qWarning("failed to load icon '%s' (%s)", qPrintable(path),
             qPrintable(r.errorString()));
    return {};
  }

  QImage out(px, px, QImage::Format_ARGB32_Premultiplied);
  out.fill(Qt::transparent);
  QPainter q(&out);
  q.setRenderHint(QPainter::SmoothPixmapTransform, true);
  QSize d = in.size();
  d.scale(px, px, Qt::KeepAspectRatio);
  q.drawImage(
      QRect((px - d.width()) / 2, (px - d.height()) / 2, d.width(), d.height()),
      in);
  q.setCompositionMode(QPainter::CompositionMode_SourceIn);
  q.fillRect(out.rect(), color);
  q.end();
  out.setDevicePixelRatio(dpr);
  return out;
}

const QImage &IconCache::get(const QString &path, qreal size, qreal dpr,
                             const QColor &color) {
  const int px = qRound(size * dpr);
  if (!m_dirty && px == m_px && color == m_color && path == m_path)
    return m_img;
  m_dirty = false;
  m_px = px;
  m_color = color;
  m_path = path;
  m_img = loadTinted(path, size, dpr, color);
  return m_img;
}

} // namespace Ryu
