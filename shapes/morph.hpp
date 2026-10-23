#pragma once
#include <QList>
#include <QPointF>
#include <array>

using MorphCubic = std::array<QPointF, 4>;
using Cubics = QList<MorphCubic>;

namespace Morph {

inline constexpr int kShapeCount = 35;

struct AlignedPair {
  Cubics from;
  Cubics to;
};

const Cubics &baseCubics(int idx);
void alignCubics(Cubics &a, Cubics &b);
const AlignedPair &alignedPair(int from, int to);

} // namespace Morph
