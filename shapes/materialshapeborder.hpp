#pragma once
#include <QColor>
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>
#include <algorithm>

class MaterialShapeBorder : public QObject {
  Q_OBJECT
  QML_ANONYMOUS
  Q_PROPERTY(qreal width READ width WRITE setWidth NOTIFY widthChanged FINAL)
  Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)

public:
  explicit MaterialShapeBorder(QObject *parent = nullptr) : QObject(parent) {}

  qreal width() const { return m_width; }
  QColor color() const { return m_color; }

  void setWidth(qreal w) {
    w = std::max<qreal>(0.0, w);
    if (qFuzzyCompare(m_width + 1.0, w + 1.0))
      return;
    m_width = w;
    emit widthChanged();
  }

  void setColor(const QColor &c) {
    if (m_color == c)
      return;
    m_color = c;
    emit colorChanged();
  }

signals:
  void widthChanged();
  void colorChanged();

private:
  qreal m_width = 0.0;
  QColor m_color = Qt::transparent;
};
