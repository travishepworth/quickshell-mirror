import QtQuick
import qs.config

// A small line graph of `values` (oldest first), filled underneath.
// `maxValue` 0 scales to the largest value shown.
Canvas {
  id: root

  property var values: []
  property real maxValue: 100
  property color lineColor: Theme.accent
  property real fillOpacity: 0.2
  property real lineWidth: 2
  // How many samples the width represents, so a short history grows in
  // from the right instead of stretching
  property int capacity: 60

  onValuesChanged: requestPaint()
  onLineColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    ctx.reset();
    const vals = root.values ?? [];
    if (vals.length < 2 || width <= 0 || height <= 0)
      return;
    const max = root.maxValue > 0 ? root.maxValue : Math.max(1, ...vals);
    const step = width / Math.max(1, root.capacity - 1);
    const x0 = width - (vals.length - 1) * step;
    const inset = root.lineWidth / 2;
    const y = v => inset + (height - inset * 2) * (1 - Math.min(1, Math.max(0, v / max)));

    ctx.beginPath();
    vals.forEach((v, i) => i === 0 ? ctx.moveTo(x0, y(v)) : ctx.lineTo(x0 + i * step, y(v)));
    ctx.lineWidth = root.lineWidth;
    ctx.lineJoin = "round";
    ctx.strokeStyle = root.lineColor;
    ctx.stroke();

    ctx.lineTo(width, height);
    ctx.lineTo(x0, height);
    ctx.closePath();
    ctx.globalAlpha = root.fillOpacity;
    ctx.fillStyle = root.lineColor;
    ctx.fill();
  }
}
