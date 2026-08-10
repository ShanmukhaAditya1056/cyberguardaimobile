/**
 * Shared presentation pieces, mirroring the widgets in `lib/shared/widgets/`
 * and `lib/features/dashboard/widgets/` so a finding looks the same whichever
 * platform surfaced it.
 *
 * Each export names the Dart widget it stands in for. When the app's visual
 * language changes, the pair should change together — that is the point of
 * keeping the names aligned rather than inventing web-native equivalents.
 */

import { Link, useNavigate } from 'react-router-dom';

import { Icon } from './icons.jsx';

/* ── SmartBackButton + a module screen's AppBar ──────────────────────────── */

/**
 * The header every module screen carries: back arrow, title, optional actions.
 *
 * `SmartBackButton` pops the navigation stack when it can and falls back to
 * `/dashboard` when it cannot — reached by deep link, say. `navigate(-1)` has
 * no equivalent fallback (it is a no-op on the first entry in the history), so
 * the same guard is reproduced with the history length.
 */
export function PageHeader({ title, actions }) {
  const navigate = useNavigate();
  return (
    <div className="page-header">
      <button
        type="button"
        className="icon-btn"
        aria-label="Back"
        onClick={() => (window.history.length > 1 ? navigate(-1) : navigate('/dashboard'))}
      >
        <Icon name="arrow_back" size={24} />
      </button>
      <h1>{title}</h1>
      {actions}
    </div>
  );
}

/** Colour band for a 0-100 score, matching `ScoreCalculator.primaryColor`. */
export function scoreColor(score) {
  if (score >= 70) return 'var(--safe)';
  if (score >= 40) return 'var(--warning)';
  return 'var(--danger)';
}

/**
 * The band used on the tinted tiles, which is a different ramp from
 * `scoreColor` — `_ModuleCardWidgetState._scoreColor` picks deeper shades so
 * the number stays legible against a pastel tile.
 */
export function tileScoreColor(score) {
  if (score >= 70) return 'var(--score-good)';
  if (score >= 40) return 'var(--score-mid)';
  return 'var(--score-bad)';
}

export function scoreLabel(score) {
  if (score >= 70) return 'PROTECTED';
  if (score >= 40) return 'AT RISK';
  return 'CRITICAL';
}

/* ── SectionTitle ────────────────────────────────────────────────────────── */

export function SectionTitle({ title, actionLabel, actionTo }) {
  return (
    <div className="section">
      <h2 className="section-title">{title}</h2>
      {actionLabel && actionTo && (
        <Link className="section-action" to={actionTo}>
          {actionLabel}
          <Icon name="chevron_right" size={18} />
        </Link>
      )}
    </div>
  );
}

/* ── _ScoreHeader ────────────────────────────────────────────────────────── */

/**
 * Greeting, headline, tile and accent for the current score.
 *
 * The four bands and their exact colours come from `_ScoreHeader._palette`.
 * The copy is the app's own — `scoreGreeting*` / `scoreHeadline*` in
 * `lib/l10n/app_en.arb`, emoji included. The web build has no localisation
 * layer yet, so the English strings are inlined rather than paraphrased;
 * writing new copy here would put two different sentences on the same tile.
 */
function heroPalette(score, neverScanned) {
  if (neverScanned) {
    return {
      tile: 'var(--tile-blue)',
      accent: 'var(--accent-blue)',
      greeting: 'Hi there 👋',
      headline: "Let's secure your phone",
      icon: 'rocket_launch',
    };
  }
  if (score >= 70) {
    return {
      tile: 'var(--tile-green)',
      accent: 'var(--score-good)',
      greeting: "You're protected",
      headline: 'Everything looks healthy',
      icon: 'verified_user',
    };
  }
  if (score >= 40) {
    return {
      tile: 'var(--tile-orange)',
      accent: 'var(--score-mid)',
      greeting: 'A few things to check ⚠️',
      headline: 'Take a quick look',
      icon: 'warning_amber',
    };
  }
  return {
    tile: 'var(--tile-rose)',
    accent: 'var(--score-bad)',
    greeting: 'Action needed 🚨',
    headline: 'Critical issues found',
    icon: 'priority_high',
  };
}

/** The 110px ring inside the hero tile — `_MiniScoreRing` / `_MiniRingPainter`. */
function MiniRing({ score, accent, placeholder }) {
  const size = 110;
  const stroke = 9;
  const radius = size / 2 - 6;
  const circumference = 2 * Math.PI * radius;
  const pct = placeholder ? 0 : Math.min(100, Math.max(0, score)) / 100;

  return (
    <div className="hero-ring">
      <svg width={size} height={size} aria-hidden="true" focusable="false">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(255,255,255,0.7)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={accent}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - pct)}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
          style={{ transition: 'stroke-dashoffset 1.1s cubic-bezier(0.22,1,0.36,1)' }}
        />
      </svg>
      <div className="hero-ring-value">{placeholder ? '—' : score}</div>
      {/* `scoreLabel` before the first scan, `scoreSuffix` after it. */}
      <div className="hero-ring-suffix">{placeholder ? 'score' : '/100'}</div>
    </div>
  );
}

export function HeroScore({ score, neverScanned, lastScanAt }) {
  const p = heroPalette(score, neverScanned);
  return (
    <section
      className="hero"
      style={{ '--tile': p.tile, '--accent': p.accent }}
      aria-label={`Security score ${neverScanned ? 'not yet measured' : `${score} out of 100`}`}
    >
      <MiniRing score={score} accent={p.accent} placeholder={neverScanned} />
      <div className="hero-body">
        <div className="hero-greeting">
          <Icon name={p.icon} size={14} />
          <span>{p.greeting}</span>
        </div>
        <div className="hero-headline">{p.headline}</div>
        <div className="hero-pill">
          <Icon name="schedule" size={11} />
          <span>{lastScanAt ? `Scanned ${timeAgo(lastScanAt)}` : 'Never scanned'}</span>
        </div>
      </div>
    </section>
  );
}

/* ── StatsRow ────────────────────────────────────────────────────────────── */

export function StatsRow({ totalScans, threatsFound, lastScanAt }) {
  const items = [
    {
      label: 'Total Scans',
      value: String(totalScans ?? 0),
      icon: 'shield_outlined',
      tile: 'var(--tile-blue)',
      accent: 'var(--accent-blue)',
    },
    {
      label: 'Threats',
      value: String(threatsFound ?? 0),
      icon: threatsFound > 0 ? 'warning_amber' : 'task_alt',
      tile: threatsFound > 0 ? 'var(--tile-rose)' : 'var(--tile-green)',
      accent: threatsFound > 0 ? 'var(--score-bad)' : 'var(--score-good)',
    },
    {
      label: 'Last Scan',
      value: lastScanAt ? timeAgo(lastScanAt) : 'Never',
      icon: 'schedule',
      tile: 'var(--tile-amber)',
      accent: 'var(--accent-amber)',
    },
  ];

  return (
    <div className="stats">
      {items.map((s) => (
        <div
          className="stat"
          key={s.label}
          style={{ '--tile': s.tile, '--accent': s.accent }}
        >
          <div className="stat-icon">
            <Icon name={s.icon} size={15} />
          </div>
          <div className="stat-value">{s.value}</div>
          <div className="stat-label">{s.label}</div>
        </div>
      ))}
    </div>
  );
}

/* ── ModuleGrid ──────────────────────────────────────────────────────────── */

export function ModuleCard({ title, subtitle, icon, tile, accent, score, to }) {
  return (
    <Link className="module" to={to} style={{ '--tile': tile, '--accent': accent }}>
      <div className="module-top">
        <div className="module-icon">
          <Icon name={icon} size={22} />
        </div>
        <div className="module-arrow">
          <Icon name="arrow_outward" size={16} />
        </div>
      </div>
      <div>
        <div className="module-title">{title}</div>
        <div className="module-sub">{subtitle}</div>
      </div>
      <div className="module-score" style={{ '--score': tileScoreColor(score) }}>
        <span className="module-score-dot" />
        <span className="module-score-value">{score}</span>
        <span className="module-score-max">/100</span>
      </div>
    </Link>
  );
}

/* ── _DefenseGrid ────────────────────────────────────────────────────────── */

export function DefenseTile({ label, icon, accent, to }) {
  return (
    <Link className="card defense" to={to} style={{ '--accent': accent, marginBottom: 0 }}>
      <div className="defense-icon">
        <Icon name={icon} size={20} />
      </div>
      <span className="defense-label">{label}</span>
    </Link>
  );
}

/* ── ScoreRing (the full-size one on result screens) ─────────────────────── */

/**
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
          <span style={{ fontSize: '16px', color: 'var(--text-light)' }}>/100</span>
        </div>
        <div className="score-label" style={{ color }}>
          {label ?? scoreLabel(score)}
        </div>
      </div>
    </div>
  );
}

/* ── RiskBadge ───────────────────────────────────────────────────────────── */

const BADGE_ICON = {
  critical: 'priority_high',
  high: 'warning_amber',
  medium: 'info_outline',
  low: 'task_alt',
  safe: 'verified_user',
};

export function RiskBadge({ level }) {
  const key = String(level).toLowerCase();
  return (
    <span className={`badge ${key}`}>
      <Icon name={BADGE_ICON[key] ?? 'info_outline'} size={12} />
      {key}
    </span>
  );
}

/* ── ShapBar ─────────────────────────────────────────────────────────────── */

/**
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
              <span className="muted">{positive ? 'raises risk' : 'lowers risk'}</span>
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
            <span className="visually-hidden">{c.passed ? ' passed' : ' failed'}</span>
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

/* ── EmptyState ──────────────────────────────────────────────────────────── */

export function EmptyState({ title, hint }) {
  return (
    <div className="empty">
      <strong className="empty-title">{title}</strong>
      {hint && <div className="empty-hint">{hint}</div>}
    </div>
  );
}

export function Spinner({ dark = false }) {
  return <span className={dark ? 'spinner dark' : 'spinner'} aria-hidden="true" />;
}

/* ── Tab bar (_GlassTabBar) ──────────────────────────────────────────────── */

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

/* ── DateFormatter ───────────────────────────────────────────────────────── */

export function formatDate(value) {
  if (!value) return '—';
  return new Date(value).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

/** `DateFormatter.timeOnly` — 24-hour HH:mm, as the app renders it. */
export function timeOnly(value) {
  if (!value) return '—';
  const d = new Date(value);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

/** `DateFormatter.timeAgo` — same thresholds, same wording, same pluralisation. */
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
 * `DateFormatter.dayLabel` — the heading above each day's scans.
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
