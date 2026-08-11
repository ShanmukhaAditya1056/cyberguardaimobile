/**
 * The console's presentation pieces.
 *
 * These no longer mirror the app's widgets one-for-one, and deliberately so:
 * the phone is a light consumer tool read a screen at a time, this is a dark
 * console read a table at a time. What the two builds share is the *verdict* —
 * the same engines, the same numbers, the same severity vocabulary — not the
 * chrome around it.
 *
 * Every export keeps the signature the pages already call, so the rewrite is
 * confined to this file and index.css.
 */

import { Link, useNavigate } from 'react-router-dom';

import { Icon } from './icons.jsx';

/* ── Severity ─────────────────────────────────────────────────────────────
   The engines emit four ordered levels — low, medium, high, critical — plus
   the words "safe" and "dangerous" from the phishing path. Everything is
   normalised here so one vocabulary reaches the screen. */

const SEVERITY_ALIASES = {
  safe: 'low',
  clean: 'low',
  suspicious: 'medium',
  warning: 'medium',
  dangerous: 'high',
  phishing: 'high',
};

export function normalizeSeverity(level) {
  const key = String(level ?? '').toLowerCase();
  return SEVERITY_ALIASES[key] ?? (['low', 'medium', 'high', 'critical'].includes(key) ? key : 'low');
}

const SEVERITY_ICON = {
  low: 'check_circle',
  medium: 'info_outline',
  high: 'warning_amber',
  critical: 'priority_high',
};

const SEVERITY_WORD = {
  low: 'Low',
  medium: 'Medium',
  high: 'High',
  critical: 'Critical',
};

/**
 * Severity, carried three ways at once: a glyph, a word, and a coloured dot.
 *
 * Never fewer than three. `critical` measures 3.62:1 on the console surface —
 * fine for a dot, short of the 4.5 small text needs — so the hue sits on the
 * dot while the label wears an ink token. That also means the badge survives
 * greyscale printing, forced-colors mode, and every form of colour blindness,
 * none of which the hue alone would.
 */
export function RiskBadge({ level }) {
  const key = normalizeSeverity(level);
  return (
    <span className={`sev ${key}`}>
      <span className="dot" aria-hidden="true" />
      <Icon name={SEVERITY_ICON[key]} size={12} />
      {SEVERITY_WORD[key]}
    </span>
  );
}

/** Maps a 0-100 score to a severity token. High score = low risk. */
export function severityForScore(score) {
  if (score >= 80) return 'low';
  if (score >= 60) return 'medium';
  if (score >= 35) return 'high';
  return 'critical';
}

export function scoreColor(score) {
  return `var(--sev-${severityForScore(score)})`;
}

/** Kept for call sites that predate the console palette; same ramp now. */
export const tileScoreColor = scoreColor;

export function scoreLabel(score) {
  if (score >= 80) return 'PROTECTED';
  if (score >= 60) return 'FAIR';
  if (score >= 35) return 'AT RISK';
  return 'CRITICAL';
}

/* ── Page furniture ───────────────────────────────────────────────────────── */

/**
 * A page's heading.
 *
 * The back button the phone carries is gone: the rail keeps every destination
 * one click away, so there is nothing to go back *to*. It survives only as the
 * deep-link fallback below when a page is opened without history.
 */
export function PageHeader({ title, sub, actions }) {
  return (
    <div className="page-header">
      <div>
        <h1>{title}</h1>
        {sub && <div className="sub">{sub}</div>}
      </div>
      {actions && <div className="actions">{actions}</div>}
    </div>
  );
}

export function BackButton() {
  const navigate = useNavigate();
  return (
    <button
      type="button"
      className="icon-btn"
      aria-label="Back"
      onClick={() => (window.history.length > 1 ? navigate(-1) : navigate('/dashboard'))}
    >
      <Icon name="arrow_back" size={20} />
    </button>
  );
}

export function SectionTitle({ title, actionLabel, actionTo }) {
  return (
    <div className="section-title">
      <span>{title}</span>
      {actionLabel && actionTo && (
        <Link className="section-action" to={actionTo}>
          {actionLabel} →
        </Link>
      )}
    </div>
  );
}

/* ── Score display ────────────────────────────────────────────────────────── */

/**
 * The headline score.
 *
 * The number is real text beside the arc, not painted inside it, so a screen
 * reader gets the value and it stays legible at any zoom — the ring is
 * decoration layered on top of a readable figure, never the only carrier.
 */
export function ScoreRing({ score, label, size = 116 }) {
  const stroke = 8;
  const radius = (size - stroke - 6) / 2;
  const circumference = 2 * Math.PI * radius;
  const pct = Math.min(100, Math.max(0, score ?? 0)) / 100;
  const color = scoreColor(score ?? 0);

  return (
    <div className="score-ring" style={{ width: size, height: size }}>
      <svg width={size} height={size} aria-hidden="true" focusable="false">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--surface-3)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - pct)}
          style={{ transition: 'stroke-dashoffset 0.9s cubic-bezier(0.22,1,0.36,1)' }}
        />
      </svg>
      <div className="score-value">{score ?? '—'}</div>
      <div className="score-label">{label ?? scoreLabel(score ?? 0)}</div>
    </div>
  );
}

export function HeroScore({ score, neverScanned, lastScanAt }) {
  const value = neverScanned ? null : score;
  return (
    <section
      className="hero"
      aria-label={
        neverScanned ? 'Security score not yet measured' : `Security score ${score} out of 100`
      }
    >
      <ScoreRing score={value} label={neverScanned ? 'NO DATA' : undefined} />
      <div className="hero-body">
        <div className="section-title" style={{ marginBottom: 6 }}>
          Security posture
        </div>
        <div className="hero-value">
          {neverScanned ? '—' : score}
          <span className="unit"> /100</span>
        </div>
        <p className="muted" style={{ marginTop: 8 }}>
          {neverScanned
            ? 'Nothing scanned yet. Run any scanner and this becomes a live figure.'
            : scoreNarrative(score)}
        </p>
        <div className="hint" style={{ marginTop: 8 }}>
          <Icon name="schedule" size={12} /> {lastScanAt ? `Last scan ${timeAgo(lastScanAt)}` : 'Never scanned'}
        </div>
      </div>
    </section>
  );
}

function scoreNarrative(score) {
  if (score >= 80) return 'No outstanding findings. Keep scanning new links and apps as they arrive.';
  if (score >= 60) return 'Mostly healthy, with a few findings worth reviewing below.';
  if (score >= 35) return 'Several findings need attention. Start with the highest severity.';
  return 'Critical findings are open. Address these before anything else.';
}

/* ── Stats ────────────────────────────────────────────────────────────────── */

export function Stat({ label, value, unit, icon }) {
  return (
    <div className="stat">
      <div className="stat-label">
        {icon && <Icon name={icon} size={13} className="stat-icon" />}
        {label}
      </div>
      <div className="stat-value">
        {value}
        {unit && <span className="unit">{unit}</span>}
      </div>
    </div>
  );
}

export function StatsRow({ totalScans, threatsFound, lastScanAt }) {
  return (
    <div className="stats">
      <Stat label="Total scans" value={totalScans ?? 0} icon="shield_outlined" />
      <Stat
        label="Threats found"
        value={threatsFound ?? 0}
        icon={threatsFound > 0 ? 'warning_amber' : 'task_alt'}
      />
      <Stat label="Last scan" value={lastScanAt ? timeAgo(lastScanAt) : 'Never'} icon="schedule" />
    </div>
  );
}

/* ── Navigation cards ─────────────────────────────────────────────────────── */

export function ModuleCard({ title, subtitle, icon, score, to }) {
  const sev = severityForScore(score);
  return (
    <Link className={`card sev-edge ${sev}`} to={to} style={{ display: 'block' }}>
      <div className="spread" style={{ marginBottom: 12 }}>
        <span className="scan-icon">
          <Icon name={icon} size={17} />
        </span>
        <RiskBadge level={sev} />
      </div>
      <div style={{ fontWeight: 600 }}>{title}</div>
      <div className="hint">{subtitle}</div>
      <div className="stat-value" style={{ fontSize: 22, marginTop: 10 }}>
        {score}
        <span className="unit">/100</span>
      </div>
    </Link>
  );
}

export function DefenseTile({ label, icon, to }) {
  return (
    <Link className="card" to={to} style={{ display: 'block' }}>
      <span className="scan-icon" style={{ marginBottom: 10 }}>
        <Icon name={icon} size={17} />
      </span>
      <div style={{ fontWeight: 600 }}>{label}</div>
    </Link>
  );
}

/* ── Explanations ─────────────────────────────────────────────────────────── */

/**
 * SHAP contributions.
 *
 * Magnitude, so one hue rather than a palette, and the direction is stated in
 * words — "raises risk" / "lowers risk" — because a bar that is merely longer
 * does not say which way it pushed.
 */
export function ShapBars({ reasons }) {
  if (!reasons?.length) return null;
  const rows = reasons.map((r, i) => ({
    key: `${typeof r === 'string' ? r : r.feature}-${i}`,
    feature: typeof r === 'string' ? r : r.feature,
    contribution: typeof r === 'string' ? 0.5 : Math.abs(r.contribution ?? 0.5),
    positive: typeof r === 'string' ? true : r.positive !== false,
  }));

  return (
    <div className="shap">
      <div className="shap-head">Why this verdict</div>
      {rows.map((r) => (
        <div className="shap-row" key={r.key}>
          <div>
            <div>{r.feature}</div>
            <div className="shap-track" style={{ marginTop: 5 }}>
              <span style={{ width: `${Math.round(Math.min(1, r.contribution) * 100)}%` }} />
            </div>
          </div>
          <span className="hint" style={{ textAlign: 'right' }}>
            {r.positive ? 'raises risk' : 'lowers risk'}
          </span>
        </div>
      ))}
    </div>
  );
}

export function CheckList({ checks }) {
  if (!checks?.length) return null;
  return (
    <div className="list">
      {checks.map((c) => (
        <div className="scan-row" key={c.name}>
          <span
            className="scan-icon"
            style={{ color: c.passed ? 'var(--sev-low)' : 'var(--sev-high)' }}
          >
            <Icon name={c.passed ? 'check_circle' : 'error_circle'} size={16} />
          </span>
          <div className="scan-body">
            <div style={{ fontWeight: 500 }}>
              {c.name}
              <span className="visually-hidden">{c.passed ? ' — passed' : ' — failed'}</span>
            </div>
            {c.detail && <div className="hint">{c.detail}</div>}
          </div>
        </div>
      ))}
    </div>
  );
}

/* ── Feedback ─────────────────────────────────────────────────────────────── */

const BANNER_ICON = {
  info: 'info_outline',
  success: 'check_circle',
  warn: 'warning_amber',
  error: 'error_circle',
};

export function Banner({ kind = 'info', children }) {
  if (!children) return null;
  return (
    <div className={`banner ${kind}`} role={kind === 'error' ? 'alert' : 'status'}>
      <Icon name={BANNER_ICON[kind] ?? 'info_outline'} size={16} className="glyph" />
      <div>{children}</div>
    </div>
  );
}

export function EmptyState({ title, hint, icon = 'shield_outlined' }) {
  return (
    <div className="empty">
      <Icon name={icon} size={30} className="glyph" />
      <h3>{title}</h3>
      {hint && <p>{hint}</p>}
    </div>
  );
}

export function Spinner() {
  return <span className="spinner" aria-hidden="true" />;
}

/**
 * A placeholder shaped like the content that is coming.
 *
 * Preferred over a spinner wherever the layout is known, because the page does
 * not jump when the data lands — and on a console, a reflow is what makes you
 * misread the row you were already looking at.
 */
export function Skeleton({ rows = 3, height = 48 }) {
  return (
    <div className="stack" aria-hidden="true">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="skel" style={{ height }} />
      ))}
    </div>
  );
}

export function Tabs({ tabs, active, onSelect }) {
  return (
    <div className="tabs" role="tablist">
      {tabs.map((t) => (
        <button
          key={t.key}
          type="button"
          role="tab"
          aria-selected={active === t.key}
          onClick={() => onSelect(t.key)}
        >
          {t.label}
        </button>
      ))}
    </div>
  );
}

/* ── Dates ────────────────────────────────────────────────────────────────── */

export function formatDate(value) {
  if (!value) return '—';
  return new Date(value).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

export function timeOnly(value) {
  if (!value) return '—';
  const d = new Date(value);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

export function timeAgo(value) {
  if (!value) return 'Never';
  const ms = Date.now() - new Date(value).getTime();
  const plural = (n, unit) => `${n} ${unit}${n > 1 ? 's' : ''} ago`;

  const seconds = Math.floor(ms / 1000);
  if (seconds < 60) return 'Just now';
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return plural(minutes, 'minute');
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return plural(hours, 'hour');
  const days = Math.floor(hours / 24);
  if (days < 7) return plural(days, 'day');
  if (days < 30) return plural(Math.floor(days / 7), 'week');
  if (days < 365) return plural(Math.floor(days / 30), 'month');
  return plural(Math.floor(days / 365), 'year');
}

/**
 * The heading above each day's scans.
 *
 * Compares calendar days rather than elapsed hours, so a scan at 23:00 is
 * "Yesterday" at 01:00 the next morning rather than "Today".
 */
export function dayLabel(value) {
  const d = new Date(value);
  const now = new Date();
  const midnight = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const diff = Math.round((midnight(now) - midnight(d)) / 86_400_000);
  if (diff === 0) return 'Today';
  if (diff === 1) return 'Yesterday';
  // Dart's DateTime.weekday is 1=Monday; JS getDay() is 0=Sunday.
  return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(d.getDay() + 6) % 7];
}
