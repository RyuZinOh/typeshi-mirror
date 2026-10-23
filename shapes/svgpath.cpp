#include "./svgpath.hpp"
#include <QString>
#include <QStringView>

QPainterPath parseSvgPath(const char *data) {
  const QString d = QString::fromLatin1(data);
  QPainterPath path;
  path.setFillRule(Qt::WindingFill);
  const QChar *p = d.constData();
  const QChar *end = p + d.size();

  auto skip = [&] {
    while (p < end && (p->isSpace() || *p == ','))
      ++p;
  };

  auto num = [&](double &out) {
    skip();
    const QChar *s = p;
    if (p < end && (*p == '-' || *p == '+'))
      ++p;
    bool dot = false;
    while (p < end && (p->isDigit() || (*p == '.' && !dot))) {
      if (*p == '.')
        dot = true;
      ++p;
    }
    if (p < end && (*p == 'e' || *p == 'E')) {
      ++p;
      if (p < end && (*p == '-' || *p == '+'))
        ++p;
      while (p < end && p->isDigit())
        ++p;
    }
    if (p == s)
      return false;
    bool ok = false;
    out = QStringView(s, p - s).toDouble(&ok);
    return ok;
  };

  QPointF cur, start, lastCtrl;
  char cmd = 0, prev = 0;
  double a[6];

  auto get = [&](int n) {
    for (int i = 0; i < n; ++i)
      if (!num(a[i]))
        return false;
    return true;
  };

  while (true) {
    skip();
    if (p >= end)
      break;
    if (p->isLetter()) {
      cmd = p->toLatin1();
      ++p;
      if (cmd == 'Z' || cmd == 'z') {
        path.closeSubpath();
        cur = start;
        prev = 'Z';
        continue;
      }
    }

    const bool rel = (cmd >= 'a' && cmd <= 'z');
    const char up = rel ? char(cmd - 32) : cmd;
    const QPointF o = rel ? cur : QPointF();

    if (up == 'M') {
      if (!get(2))
        break;
      cur = start = o + QPointF(a[0], a[1]);
      path.moveTo(cur);
      cmd = rel ? 'l' : 'L';
    } else if (up == 'L') {
      if (!get(2))
        break;
      cur = o + QPointF(a[0], a[1]);
      path.lineTo(cur);
    } else if (up == 'H') {
      if (!get(1))
        break;
      cur.setX((rel ? cur.x() : 0) + a[0]);
      path.lineTo(cur);
    } else if (up == 'V') {
      if (!get(1))
        break;
      cur.setY((rel ? cur.y() : 0) + a[0]);
      path.lineTo(cur);
    } else if (up == 'C') {
      if (!get(6))
        break;
      const QPointF c1 = o + QPointF(a[0], a[1]);
      const QPointF c2 = o + QPointF(a[2], a[3]);
      const QPointF e = o + QPointF(a[4], a[5]);
      path.cubicTo(c1, c2, e);
      lastCtrl = c2;
      cur = e;
    } else if (up == 'S') {
      if (!get(4))
        break;
      const QPointF c1 =
          (prev == 'C' || prev == 'S') ? 2 * cur - lastCtrl : cur;
      const QPointF c2 = o + QPointF(a[0], a[1]);
      const QPointF e = o + QPointF(a[2], a[3]);
      path.cubicTo(c1, c2, e);
      lastCtrl = c2;
      cur = e;
    } else {
      qWarning("MaterialShape: unsupported path command '%c'", cmd);
      break;
    }
    prev = up;
  }
  return path;
}
