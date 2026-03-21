/**
 * LineChart — lightweight SVG line chart for trends.
 * No external dependencies. Renders a responsive SVG with:
 *   - Line path with gradient fill
 *   - Y-axis labels (min/max)
 *   - X-axis date labels (first/last)
 *   - Hover/tap tooltip
 *   - Optional "higher is better" / "lower is better" coloring
 */
import { useState, useMemo } from 'react';

export interface ChartDataPoint {
  date: string;   // display label (e.g. "Mar 15")
  value: number;
}

export interface LineChartProps {
  data: ChartDataPoint[];
  /** Color for the line and gradient. Default: accent orange */
  color?: string;
  /** Height in px. Default: 200 */
  height?: number;
  /** Format function for Y-axis values */
  formatValue?: (v: number) => string;
  /** If true, lower values are "better" (line colored green when trending down) */
  lowerIsBetter?: boolean;
}

const DEFAULT_COLOR = '#F2731A';

export function LineChart({
  data,
  color = DEFAULT_COLOR,
  height = 200,
  formatValue = (v) => String(Math.round(v)),
  lowerIsBetter = false,
}: LineChartProps) {
  const [tooltip, setTooltip] = useState<{ x: number; point: ChartDataPoint } | null>(null);

  const { points, minVal, maxVal, svgPath, fillPath } = useMemo(() => {
    if (data.length < 2) return { points: [], minVal: 0, maxVal: 0, svgPath: '', fillPath: '' };

    const vals = data.map((d) => d.value);
    const min = Math.min(...vals);
    const max = Math.max(...vals);
    const range = max - min || 1;
    const padding = range * 0.1;
    const effMin = min - padding;
    const effMax = max + padding;
    const effRange = effMax - effMin;

    const MARGIN_LEFT = 0;
    const MARGIN_RIGHT = 0;
    const MARGIN_TOP = 10;
    const MARGIN_BOTTOM = 10;
    const chartW = 100 - MARGIN_LEFT - MARGIN_RIGHT;
    const chartH = height - MARGIN_TOP - MARGIN_BOTTOM;

    const pts = data.map((d, i) => ({
      x: MARGIN_LEFT + (i / (data.length - 1)) * chartW,
      y: MARGIN_TOP + (1 - (d.value - effMin) / effRange) * chartH,
      point: d,
    }));

    const pathD = pts.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
    const fillD = `${pathD} L ${pts[pts.length - 1].x} ${MARGIN_TOP + chartH} L ${pts[0].x} ${MARGIN_TOP + chartH} Z`;

    return { points: pts, minVal: min, maxVal: max, svgPath: pathD, fillPath: fillD };
  }, [data, height]);

  if (data.length < 2) {
    return (
      <div style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '24px 0', fontSize: 'var(--font-body-small)' }}>
        Need at least 2 data points to show a chart.
      </div>
    );
  }

  const gradientId = `grad-${color.replace('#', '')}`;

  // Trend direction
  const trending = data[data.length - 1].value - data[0].value;
  const trendColor = lowerIsBetter
    ? (trending <= 0 ? '#66BB6A' : '#EF5350')
    : (trending >= 0 ? '#66BB6A' : '#EF5350');

  return (
    <div style={{ position: 'relative' }}>
      {/* Y-axis labels */}
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-micro)', color: 'var(--text-muted)', marginBottom: 2 }}>
        <span>{formatValue(maxVal)}</span>
        <span style={{ color: trendColor, fontWeight: 'bold' }}>
          {trending > 0 ? '+' : ''}{formatValue(trending)}
        </span>
      </div>

      <svg
        viewBox={`0 0 100 ${height}`}
        preserveAspectRatio="none"
        style={{ width: '100%', height, display: 'block' }}
        onMouseLeave={() => setTooltip(null)}
      >
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.3" />
            <stop offset="100%" stopColor={color} stopOpacity="0.02" />
          </linearGradient>
        </defs>

        {/* Fill area */}
        <path d={fillPath} fill={`url(#${gradientId})`} />

        {/* Line */}
        <path
          d={svgPath}
          fill="none"
          stroke={color}
          strokeWidth="0.8"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />

        {/* Data points (interactive) */}
        {points.map((p, i) => (
          <circle
            key={i}
            cx={p.x}
            cy={p.y}
            r="1.5"
            fill={color}
            stroke="white"
            strokeWidth="0.5"
            style={{ cursor: 'pointer' }}
            onMouseEnter={() => setTooltip({ x: p.x, point: p.point })}
            onClick={() => setTooltip(tooltip?.point === p.point ? null : { x: p.x, point: p.point })}
          />
        ))}
      </svg>

      {/* X-axis labels */}
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 'var(--font-micro)', color: 'var(--text-muted)', marginTop: 2 }}>
        <span>{data[0].date}</span>
        <span>{formatValue(minVal)}</span>
        <span>{data[data.length - 1].date}</span>
      </div>

      {/* Tooltip */}
      {tooltip && (
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: `${tooltip.x}%`,
            transform: 'translateX(-50%)',
            background: 'var(--color-navy)',
            color: 'var(--color-cream)',
            padding: '4px 10px',
            borderRadius: 'var(--radius-sm)',
            fontSize: 'var(--font-micro)',
            fontWeight: 'bold',
            whiteSpace: 'nowrap',
            pointerEvents: 'none',
            zIndex: 10,
          }}
        >
          {tooltip.point.date}: {formatValue(tooltip.point.value)}
        </div>
      )}
    </div>
  );
}
