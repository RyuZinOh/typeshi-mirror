#pragma once
#include <QColor>
#include <QFont>
#include <QImage>
#include <QPainter>
#include <QPainterPath>
#include <QPointF>
#include <QRectF>
#include <QString>
#include <QUrl>

class QQmlContext;

namespace Ryu {

inline constexpr qreal kDisabledOpacity = 0.38;
inline constexpr qreal kHoverLayer = 0.08;
inline constexpr qreal kPressLayer = 0.10;

inline qreal stateLayer(bool hovered, bool active) {
  return active ? kPressLayer : (hovered ? kHoverLayer : 0.0);
}

inline QColor withAlpha(QColor c, qreal a) {
  c.setAlphaF(a);
  return c;
}

QColor mix(const QColor &a, const QColor &b, qreal t);

QPainterPath roundedRect(const QRectF &r, qreal tl, qreal tr, qreal br,
                         qreal bl);

inline QPainterPath sidedRect(const QRectF &r, qreal left, qreal right) {
  return roundedRect(r, left, right, right, left);
}

QFont styledFont(const QFont &base, qreal px, int weight = QFont::Normal);

void drawGlyph(QPainter *p, const QFont &font, const QString &text,
               const QPointF &center, qreal size, const QColor &color);

void drawLabel(QPainter *p, const QFont &font, const QString &text, qreal x,
               qreal cy, const QColor &color);

void strokeInside(QPainter *p, const QPainterPath &path, const QColor &color,
                  qreal width);

QString resolveUrl(const QQmlContext *ctx, const QUrl &url);

QImage loadTinted(const QString &path, qreal size, qreal dpr,
                  const QColor &color);

class IconCache {
public:
  void invalidate() { m_dirty = true; }
  const QImage &get(const QString &path, qreal size, qreal dpr,
                    const QColor &color);

private:
  QImage m_img;
  QString m_path;
  QColor m_color;
  int m_px = 0;
  bool m_dirty = true;
};

} // namespace Ryu
