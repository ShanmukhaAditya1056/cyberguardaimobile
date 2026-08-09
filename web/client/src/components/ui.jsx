/**
 * Shared presentation pieces, mirroring the widgets in `lib/shared/widgets/`
 * so a finding looks the same whichever platform surfaced it.
 */

/** Colour band for a 0-100 score, matching `ScoreCalculator.primaryColor`. */
export function scoreColor(score) {
  if (score >= 70) return 'var(--safe)';
  if (score >= 40) return 'var(--warning)';
  return 'var(--danger)';
}

export function scoreLabel(score) {
  if (score >= 70) return 'PROTECTED';
  if (score >= 40) return 'AT RISK';
  return 'CRITICAL';
}

/**
 * The unified score as a ring.
 *
 * The number is rendered as text alongside, not only inside the ring, so the
 * value is available to a screen reader and legible at any zoom level — the
 * arc is decoration on top of it.
 */
export function ScoreRing({ score, label, size = 120 }) {
  const radius = (size - 14) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - Math.min(100, Math.max(0, score)) / 100);
  const color = scoreColor(score);

  return (
    <div className="score-ring">
      <svg width={size} height={size} aria-hidden="true" focusable="false">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--divider)"
          strokeWidth="9"
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="9"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <div>
        <div className="score-value" style={{ color }}>
          {score}
          <span style={{ fontSize: '1rem', color: 'var(--text-light)' }}>/100</span>
        </div>
        <div className="score-label" style={{ color }}>
          {label ?? scoreLabel(score)}
        </div>
      </div>
    </div>
  );
}

export function RiskBadge({ level }) {
  return <span className={`badge ${level}`}>{level}</span>;
}

/**
 * SHAP-style contribution bars.
 *
 * Direction is encoded in the label ("raises risk" / "lowers risk") as well as
 * in the bar colour, so the explanation still reads correctly for someone who
 * cannot distinguish the red and green.
 */
export function ShapBars({ reasons }) {
  if (!reasons?.length) return null;
  return (
    <div className="shap">
      {reasons.map((r, i) => {
        const contribution = typeof r === 'string' ? 0.5 : r.contribution;
        const feature = typeof r === 'string' ? r : r.feature;
        const positive = typeof r === 'string' ? true : r.positive;
        return (
          <div className="shap-row" key={`${feature}-${i}`}>
            <div className="shap-head">
              <span>{feature}</span>
              <span className="muted">
                {positive ? 'raises risk' : 'lowers risk'}
              </span>
            </div>
            <div className="shap-track">
              <div
                className={`shap-fill ${positive ? 'up' : 'down'}`}
                style={{ width: `${Math.round(contribution * 100)}%` }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function CheckList({ checks }) {
  return (
    <div>
      {checks.map((c) => (
        <div className={`check ${c.passed ? 'pass' : 'fail'}`} key={c.name}>
          <span className="check-icon" aria-hidden="true">
            {c.passed ? '✓' : '✕'}
          </span>
          <div>
            <strong>{c.name}</strong>
            <span className="visually-hidden">
              {c.passed ? ' passed' : ' failed'}
            </span>
            <div className="muted">{c.detail}</div>
          </div>
        </div>
      ))}
    </div>
  );
}

export function Banner({ kind = 'info', children }) {
  if (!children) return null;
  return (
    <div className={`banner ${kind}`} role={kind === 'error' ? 'alert' : 'status'}>
      {children}
    </div>
  );
}

export function EmptyState({ title, hint }) {
  return (
    <div className="empty">
      <strong>{title}</strong>
      {hint && <div style={{ marginTop: 6 }}>{hint}</div>}
    </div>
  );
}

export function Spinner() {
  return <span className="spinner" aria-hidden="true" />;
}

export function formatDate(value) {
  if (!value) return '—';
  return new Date(value).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}
