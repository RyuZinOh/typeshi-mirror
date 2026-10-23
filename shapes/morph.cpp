#include "./morph.hpp"
#include "./svgpath.hpp"
#include <QHash>
#include <QLineF>
#include <QRectF>
#include <algorithm>
#include <limits>

namespace {

struct ShapeData {
  const char *name;
  const char *d;
  float vbX, vbY, vbW, vbH;
};

#include "./shapedata.inc"

static_assert(sizeof(kShapeTable) / sizeof(kShapeTable[0]) ==
                  Morph::kShapeCount,
              "shape table must match Morph::kShapeCount");

bool samePoint(const QPointF &a, const QPointF &b) {
  return (a - b).manhattanLength() < 1e-9;
}

Cubics toCubics(const QPainterPath &path, const QPointF &center, qreal k) {
  Cubics out;
  const int count = path.elementCount();
  out.reserve(count / 3 + 2);
  auto nrm = [&](const QPointF &p) { return (p - center) * k; };
  auto line = [&](const QPointF &a, const QPointF &b) {
    if (samePoint(a, b))
      return;
    out.push_back(MorphCubic{a, a + (b - a) / 3.0, a + (b - a) * 2.0 / 3.0, b});
  };

  QPointF cur, start;
  for (int i = 0; i < count; ++i) {
    const QPainterPath::Element e = path.elementAt(i);
    const QPointF pt(e.x, e.y);
    switch (e.type) {
    case QPainterPath::MoveToElement:
      cur = start = pt;
      break;
    case QPainterPath::LineToElement:
      line(nrm(cur), nrm(pt));
      cur = pt;
      break;
    case QPainterPath::CurveToElement: {
      if (i + 2 >= count)
        break;
      const QPainterPath::Element e2 = path.elementAt(i + 1);
      const QPainterPath::Element e3 = path.elementAt(i + 2);
      const QPointF c2(e2.x, e2.y);
      const QPointF end(e3.x, e3.y);
      out.push_back(MorphCubic{nrm(cur), nrm(pt), nrm(c2), nrm(end)});
      cur = end;
      i += 2;
      break;
    }
    default:
      break;
    }
  }
  if (!samePoint(cur, start))
    line(nrm(cur), nrm(start));
  return out;
}

qreal approxLength(const MorphCubic &c) {
  return QLineF(c[0], c[1]).length() + QLineF(c[1], c[2]).length() +
         QLineF(c[2], c[3]).length();
}

void splitCubic(const MorphCubic &c, MorphCubic &l, MorphCubic &r) {
  const QPointF p01 = (c[0] + c[1]) / 2.0;
  const QPointF p12 = (c[1] + c[2]) / 2.0;
  const QPointF p23 = (c[2] + c[3]) / 2.0;
  const QPointF p012 = (p01 + p12) / 2.0;
  const QPointF p123 = (p12 + p23) / 2.0;
  const QPointF m = (p012 + p123) / 2.0;
  l = MorphCubic{c[0], p01, p012, m};
  r = MorphCubic{m, p123, p23, c[3]};
}

void subdivideTo(Cubics &v, int n) {
  if (v.isEmpty())
    return;
  QList<qreal> lens;
  lens.reserve(n);
  for (const MorphCubic &c : std::as_const(v))
    lens.push_back(approxLength(c));

  while (v.size() < n) {
    const int best =
        int(std::max_element(lens.cbegin(), lens.cend()) - lens.cbegin());
    MorphCubic l, r;
    splitCubic(v[best], l, r);
    v[best] = l;
    v.insert(best + 1, r);
    lens[best] = approxLength(l);
    lens.insert(best + 1, approxLength(r));
  }
}

Cubics reversed(const Cubics &v) {
  Cubics out;
  out.reserve(v.size());
  for (int i = v.size() - 1; i >= 0; --i) {
    MorphCubic c = v[i];
    std::swap(c[0], c[3]);
    std::swap(c[1], c[2]);
    out.push_back(c);
  }
  return out;
}

int bestShift(const Cubics &a, const Cubics &b, qreal &bestCost) {
  const int n = a.size();
  int shift = 0;
  bestCost = std::numeric_limits<qreal>::max();
  for (int k = 0; k < n; ++k) {
    qreal cost = 0.0;
    for (int i = 0, j = k; i < n; ++i) {
      const QPointF d = a[i][0] - b[j][0];
      cost += d.x() * d.x() + d.y() * d.y();
      if (++j == n)
        j = 0;
      if (cost >= bestCost)
        break;
    }
    if (cost < bestCost) {
      bestCost = cost;
      shift = k;
    }
  }
  return shift;
}

} // namespace

namespace Morph {

const Cubics &baseCubics(int idx) {
  static const Cubics empty;
  static std::array<Cubics, kShapeCount> cache;
  static std::array<bool, kShapeCount> ready{};
  if (idx < 0 || idx >= kShapeCount)
    return empty;
  if (!ready[idx]) {
    ready[idx] = true;
    const ShapeData &sd = kShapeTable[idx];
    const QRectF vb(sd.vbX, sd.vbY, sd.vbW, sd.vbH);
    const qreal extent = std::max(vb.width(), vb.height());
    if (extent > 0)
      cache[idx] = toCubics(parseSvgPath(sd.d), vb.center(), 1.0 / extent);
  }
  return cache[idx];
}

void alignCubics(Cubics &a, Cubics &b) {
  if (a.isEmpty() || b.isEmpty())
    return;

  const int n = std::max(a.size(), b.size());
  subdivideTo(a, n);
  subdivideTo(b, n);

  Cubics rb = reversed(b);
  qreal costFwd = 0.0, costRev = 0.0;
  const int shiftFwd = bestShift(a, b, costFwd);
  const int shiftRev = bestShift(a, rb, costRev);

  if (costRev < costFwd) {
    b = std::move(rb);
    std::rotate(b.begin(), b.begin() + shiftRev, b.end());
  } else {
    std::rotate(b.begin(), b.begin() + shiftFwd, b.end());
  }
}

const AlignedPair &alignedPair(int from, int to) {
  static QHash<quint32, AlignedPair> cache;
  const quint32 key = quint32(from) * 64u + quint32(to);
  auto it = cache.find(key);
  if (it == cache.end()) {
    AlignedPair p{baseCubics(from), baseCubics(to)};
    alignCubics(p.from, p.to);
    it = cache.insert(key, std::move(p));
  }
  return it.value();
}

} // namespace Morph
