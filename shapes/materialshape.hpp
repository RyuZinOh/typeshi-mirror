#pragma once
#include "../Core/spring.hpp"
#include "./materialshapeborder.hpp"
#include "./morph.hpp"
#include <QColor>
#include <QFont>
#include <QImage>
#include <QList>
#include <QPainterPath>
#include <QQuickPaintedItem>
#include <QString>
#include <QTimer>
#include <QUrl>
#include <QtQmlIntegration/qqmlintegration.h>

class MaterialShape : public QQuickPaintedItem {
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(Type shape READ shape WRITE setShape NOTIFY shapeChanged)
  Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
  Q_PROPERTY(MaterialShapeBorder *border READ border CONSTANT)
  Q_PROPERTY(
      bool animated READ animated WRITE setAnimated NOTIFY animatedChanged)
  Q_PROPERTY(qreal springStiffness READ springStiffness WRITE setSpringStiffness
                 NOTIFY springStiffnessChanged)
  Q_PROPERTY(qreal springDamping READ springDamping WRITE setSpringDamping
                 NOTIFY springDampingChanged)
  Q_PROPERTY(bool morphing READ morphing NOTIFY morphingChanged)
  Q_PROPERTY(bool loading READ loading WRITE setLoading NOTIFY loadingChanged)
  Q_PROPERTY(int loadingGap READ loadingGap WRITE setLoadingGap NOTIFY
                 loadingGapChanged)
  Q_PROPERTY(qreal loadingKick READ loadingKick WRITE setLoadingKick NOTIFY
                 loadingKickChanged)
  Q_PROPERTY(bool loadingAllShapes READ loadingAllShapes WRITE
                 setLoadingAllShapes NOTIFY loadingAllShapesChanged)
  Q_PROPERTY(QList<int> loadingSequence READ loadingSequence WRITE
                 setLoadingSequence NOTIFY loadingSequenceChanged)
  Q_PROPERTY(
      bool contained READ contained WRITE setContained NOTIFY containedChanged)
  Q_PROPERTY(QColor containerColor READ containerColor WRITE setContainerColor
                 NOTIFY containerColorChanged)
  Q_PROPERTY(qreal containedScale READ containedScale WRITE setContainedScale
                 NOTIFY containedScaleChanged)
  Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
  Q_PROPERTY(
      FillMode fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged)
  Q_PROPERTY(QString glyph READ glyph WRITE setGlyph NOTIFY glyphChanged)
  Q_PROPERTY(
      QFont glyphFont READ glyphFont WRITE setGlyphFont NOTIFY glyphFontChanged)
  Q_PROPERTY(QColor glyphColor READ glyphColor WRITE setGlyphColor NOTIFY
                 glyphColorChanged)
  Q_PROPERTY(
      qreal glyphSize READ glyphSize WRITE setGlyphSize NOTIFY glyphSizeChanged)

public:
  enum Type {
    Circle,
    Square,
    Slanted,
    Arch,
    Fan,
    Arrow,
    SemiCircle,
    Oval,
    Pill,
    Triangle,
    Diamond,
    ClamShell,
    Pentagon,
    Gem,
    Sunny,
    VerySunny,
    Cookie4Sided,
    Cookie6Sided,
    Cookie7Sided,
    Cookie9Sided,
    Cookie12Sided,
    Ghostish,
    Clover4Leaf,
    Clover8Leaf,
    Burst,
    SoftBurst,
    Boom,
    SoftBoom,
    Flower,
    Puffy,
    PuffyDiamond,
    PixelCircle,
    PixelTriangle,
    Bun,
    Heart
  };
  Q_ENUM(Type)

  enum FillMode { Crop, Fit, Stretch };
  Q_ENUM(FillMode)

  explicit MaterialShape(QQuickItem *parent = nullptr);

  Type shape() const { return m_shape; }
  QColor color() const { return m_color; }
  MaterialShapeBorder *border() const { return m_border; }
  bool animated() const { return m_animated; }
  qreal springStiffness() const { return m_stiffness; }
  qreal springDamping() const { return m_damping; }
  bool morphing() const { return m_morphing; }
  bool loading() const { return m_loading; }
  int loadingGap() const { return m_loadGap; }
  qreal loadingKick() const { return m_loadKick; }
  bool loadingAllShapes() const { return m_loadAll; }
  QList<int> loadingSequence() const { return m_loadSeq; }
  bool contained() const { return m_contained; }
  QColor containerColor() const { return m_containerColor; }
  qreal containedScale() const { return m_containedScale; }
  QUrl source() const { return m_source; }
  FillMode fillMode() const { return m_fillMode; }
  QString glyph() const { return m_glyph; }
  QFont glyphFont() const { return m_glyphFont; }
  QColor glyphColor() const { return m_glyphColor; }
  qreal glyphSize() const { return m_glyphSize; }

  void setShape(Type t);
  void setColor(const QColor &c);
  void setAnimated(bool v);
  void setSpringStiffness(qreal v);
  void setSpringDamping(qreal v);
  void setLoading(bool v);
  void setLoadingGap(int ms);
  void setLoadingKick(qreal deg);
  void setLoadingAllShapes(bool v);
  void setLoadingSequence(const QList<int> &seq);
  void setContained(bool v);
  void setContainerColor(const QColor &v);
  void setContainedScale(qreal v);
  void setSource(const QUrl &u);
  void setFillMode(FillMode m);
  void setGlyph(const QString &v);
  void setGlyphFont(const QFont &v);
  void setGlyphColor(const QColor &v);
  void setGlyphSize(qreal v);

  void paint(QPainter *painter) override;

signals:
  void shapeChanged();
  void colorChanged();
  void animatedChanged();
  void springStiffnessChanged();
  void springDampingChanged();
  void morphingChanged();
  void loadingChanged();
  void loadingGapChanged();
  void loadingKickChanged();
  void loadingAllShapesChanged();
  void loadingSequenceChanged();
  void containedChanged();
  void containerColorChanged();
  void containedScaleChanged();
  void sourceChanged();
  void fillModeChanged();
  void glyphChanged();
  void glyphFontChanged();
  void glyphColorChanged();
  void glyphSizeChanged();

protected:
  void componentComplete() override;
  void geometryChange(const QRectF &newGeometry,
                      const QRectF &oldGeometry) override;
  void itemChange(ItemChange change, const ItemChangeData &data) override;

private:
  void rebuildPath();
  void buildImage();
  void snapTo(Type t);
  void startMorph(Type t);
  void tick(qreal dt);
  void stepMorph(qreal dt);
  bool stepRotation(qreal dt);
  void applyProgress(qreal p);
  void finishMorph();
  void setMorphing(bool v);
  void ensureDriver();
  void startLoading();
  void advanceLoading();
  void scheduleNext();
  int loadCount() const;
  Type loadShapeAt(int i) const;

  Type m_shape = Circle;
  QColor m_color = QColor("#6750A4");
  MaterialShapeBorder *m_border = nullptr;
  bool m_animated = true;
  qreal m_stiffness = 420.0;
  qreal m_damping = 0.6;
  bool m_morphing = false;

  bool m_loading = false;
  bool m_loadAll = false;
  QList<int> m_loadSeq;
  bool m_contained = false;
  QColor m_containerColor = QColor("#D0BCFF");
  qreal m_containedScale = 0.62;
  int m_loadGap = 120;
  qreal m_loadKick = 90.0;
  int m_loadIndex = 0;
  QTimer *m_loadTimer = nullptr;

  Ryu::Spring m_rot;
  Ryu::Spring m_morph{0.0, 0.0, 1.0};

  Cubics m_current;
  Cubics m_from;
  Cubics m_to;
  Ryu::SpringDriver *m_driver = nullptr;

  QPainterPath m_path;
  bool m_pathDirty = true;

  QUrl m_source;
  FillMode m_fillMode = Crop;
  QImage m_image;
  QImage m_scaled;
  bool m_imageDirty = true;

  QString m_glyph;
  QFont m_glyphFont;
  QColor m_glyphColor = QColor("#FFFFFF");
  qreal m_glyphSize = 24.0;
};
