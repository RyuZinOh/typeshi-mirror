#pragma once
#include <QAbstractAnimation>
#include <algorithm>
#include <cmath>
#include <functional>

namespace Ryu {

struct Spring {
  qreal x = 0.0;
  qreal v = 0.0;
  qreal t = 0.0;

  void go(qreal target, bool immediate = false) {
    t = target;
    if (immediate) {
      x = t;
      v = 0.0;
    }
  }
};

inline bool stepSpring(Spring &s, qreal k, qreal zeta, qreal dt, qreal eps) {
  if (std::abs(s.x - s.t) < eps && std::abs(s.v) < eps * 10.0) {
    s.x = s.t;
    s.v = 0.0;
    return false;
  }
  constexpr qreal kMaxStep = 0.004;
  const qreal c = 2.0 * zeta * std::sqrt(k);
  const int steps = std::max(1, int(std::ceil(dt / kMaxStep)));
  const qreal h = dt / steps;
  for (int i = 0; i < steps; ++i) {
    const qreal acc = -k * (s.x - s.t) - c * s.v;
    s.v += acc * h;
    s.x += s.v * h;
  }
  return true;
}

class SpringDriver : public QAbstractAnimation {
public:
  std::function<void(qreal)> tick;

  explicit SpringDriver(QObject *parent) : QAbstractAnimation(parent) {}

  int duration() const override { return -1; }

protected:
  void updateCurrentTime(int t) override {
    const qreal dt = qBound(0.0, (t - m_last) / 1000.0, 1.0 / 30.0);
    m_last = t;
    if (tick)
      tick(dt);
  }

  void updateState(State newState, State oldState) override {
    if (newState == Running && oldState == Stopped)
      m_last = 0;
  }

private:
  int m_last = 0;
};

} // namespace Ryu
