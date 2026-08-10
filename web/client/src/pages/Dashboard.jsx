/**
 * The app's dashboard, section for section.
 *
 * `_DashboardContent` in `lib/features/dashboard/view/dashboard_screen.dart`
 * builds, in order: score header, stats row, "Protection Modules" grid,
 * "Cyber Defense" grid, the 7-day chart, then this week's scans grouped by
 * day. This file builds the same sequence with the same spacing, and each
 * section is named after the Dart widget it stands in for.
 */

import { useEffect, useMemo, useState } from 'react';

import { useDashboard } from '../context/DashboardContext.jsx';
import { Icon } from '../components/icons.jsx';
import {
  Banner,
  DefenseTile,
  EmptyState,
  HeroScore,
  ModuleCard,
  SectionTitle,
  Spinner,
  StatsRow,
  dayLabel,
  scoreColor,
  timeOnly,
} from '../components/ui.jsx';
import { api } from '../lib/api.js';

/** `ModuleGrid` — the four protection modules and their tile/accent pairs. */
const MODULES = [
  {
    key: 'phishing',
    title: 'Phishing',
    subtitle: 'URL & SMS scanner',
    icon: 'link',
    tile: 'var(--tile-blue)',
    accent: 'var(--accent-blue)',
    to: '/phishing',
  },
  {
    key: 'malware',
    title: 'Malware',
    subtitle: 'App security',
    icon: 'bug_report',
    tile: 'var(--tile-orange)',
    accent: 'var(--accent-orange)',
    to: '/malware',
  },
  {
    key: 'breach',
    title: 'Breach',
    subtitle: 'Data leak monitor',
    icon: 'lock_person',
    tile: 'var(--tile-rose)',
    accent: 'var(--accent-rose)',
    to: '/breach',
  },
  {
    key: 'wifi',
    title: 'Wi-Fi',
    subtitle: 'Network analyser',
    icon: 'wifi',
    tile: 'var(--tile-green)',
    accent: 'var(--accent-green)',
    to: '/wifi',
  },
];

/**
 * `_DefenseGrid`. All four live on one page in the browser rather than on four
 * routes, so every tile deep-links into the matching tab.
 */
const DEFENSE = [
  { label: 'Threat Fusion', icon: 'travel_explore', accent: 'var(--blue)', to: '/defense' },
  // The app's Screenshot Scanner OCRs an image; the browser has no on-device
  // OCR, so its stand-in takes the text directly. Same classifier, same tile.
  { label: 'Screenshot Scan', icon: 'image_search', accent: 'var(--safe)', to: '/defense?tab=message' },
  { label: 'Predictive Risk', icon: 'online_prediction', accent: 'var(--warning)', to: '/defense?tab=risk' },
  { label: 'Arbitration Log', icon: 'balance', accent: 'var(--critical)', to: '/defense?tab=arbitration' },
];

/** `_ScanRow._moduleIcons`. */
const SCAN_ICONS = {
  phishing: 'link',
  malware: 'android',
  breach: 'mark_email_unread',
  wifi: 'wifi',
  link_intercept: 'shield',
};

/** `_ScanRow._verdictLabels` — the rest are just capitalised. */
const VERDICT_LABELS = {
  threats_found: 'Threats',
  link_intercept: 'Blocked',
};

/** Mirrors `ScanResultModel._threatVerdicts` / the server's THREAT_VERDICTS. */
const THREAT_VERDICTS = new Set([
  'phishing',
  'threats_found',
  'breached',
  'dangerous',
  'critical',
  'malicious',
  'unsafe',
]);

/** `ScoreChartWidget` — the 7-day trend. */
function ScoreChart({ points }) {
  if (points.length < 2) {
    return (
      <div className="card">
        <p className="muted" style={{ margin: 0 }}>
          Run scans on two or more days to see a trend here.
        </p>
      </div>
    );
  }

  const width = 320;
  const height = 90;
  const pad = 6;
  const step = (width - pad * 2) / (points.length - 1);
  const y = (score) => pad + (1 - score / 100) * (height - pad * 2);
  const line = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${pad + i * step} ${y(p.score)}`)
    .join(' ');
  const latest = points[points.length - 1].score;
  const colour = scoreColor(latest);

  return (
    <div className="card">
      <svg
        width="100%"
        height={height}
        viewBox={`0 0 ${width} ${height}`}
        preserveAspectRatio="none"
        role="img"
        aria-label={`Security score over the last ${points.length} days, currently ${latest} out of 100`}
      >
        <path
          d={`${line} L ${pad + (points.length - 1) * step} ${height} L ${pad} ${height} Z`}
          fill={colour}
          opacity="0.10"
        />
        <path d={line} fill="none" stroke={colour} strokeWidth="2.5" strokeLinecap="round" />
      </svg>
    </div>
  );
}

/** `_ScanRow`. */
function ScanRow({ scan }) {
  const isThreat = THREAT_VERDICTS.has(String(scan.verdict).toLowerCase());
  const tone = isThreat ? 'var(--danger)' : 'var(--safe)';
  const label =
    VERDICT_LABELS[scan.verdict] ??
    (scan.verdict ? scan.verdict[0].toUpperCase() + scan.verdict.slice(1) : '—');

  return (
    <div className="scan-row" style={{ '--tone': tone }}>
      <div className="scan-icon">
        <Icon name={SCAN_ICONS[scan.type] ?? 'security'} size={16} />
      </div>
      <div className="scan-body">
        <div className="scan-input">{scan.input || scan.type}</div>
        <div className="scan-verdict">{label}</div>
      </div>
      <div className="scan-time">{timeOnly(scan.createdAt)}</div>
    </div>
  );
}

/** `_WeekScanHistory` — grouped under a heading per day, newest day first. */
function WeekScanHistory({ scans }) {
  const byDay = useMemo(() => {
    const groups = new Map();
    for (const scan of scans) {
      const key = dayLabel(scan.createdAt);
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(scan);
    }
    return [...groups.entries()];
  }, [scans]);

  return (
    <div className="pad">
      {byDay.map(([day, rows]) => (
        <div key={day}>
          <div className="day-label">{day}</div>
          <div className="card flush">
            {rows.map((scan) => (
              <ScanRow key={scan._id} scan={scan} />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

export default function Dashboard() {
  const { data, error, loading } = useDashboard();
  const [health, setHealth] = useState(null);

  useEffect(() => {
    // Best-effort: the banner it feeds is informational, so a failure here
    // must not stop the dashboard rendering.
    api.health().then(setHealth).catch(() => {});
  }, []);

  if (error) {
    return (
      <div className="pad">
        <Banner kind="error">{error}</Banner>
      </div>
    );
  }
  if (loading || !data) {
    return (
      <div className="empty">
        <Spinner dark />
      </div>
    );
  }

  const degraded = health
    ? Object.entries(health.engines)
        .filter(([, ok]) => !ok)
        .map(([name]) => name)
    : [];
  const neverScanned = !data.lastScanAt;
  const weekScans = data.weekScans ?? [];

  return (
    <>
      {degraded.length > 0 && (
        <div className="pad">
          <Banner kind="warn">
            These models could not be loaded on the server:{' '}
            <strong>{degraded.join(', ')}</strong>. The affected scanners are still
            running, using their rules engines only — verdicts will be less precise
            than on the mobile app.
          </Banner>
        </div>
      )}

      {/* The app shows 70 as the ring's resting value before the first scan,
          so the tile is not a blank circle on a new account. */}
      <HeroScore
        score={neverScanned ? 70 : data.score}
        neverScanned={neverScanned}
        lastScanAt={data.lastScanAt}
      />

      <StatsRow
        totalScans={data.stats?.totalScans}
        threatsFound={data.stats?.threatsFound}
        lastScanAt={data.lastScanAt}
      />

      <div style={{ height: 24 }} />
      <SectionTitle title="Protection Modules" />
      <div className="module-grid">
        {MODULES.map((m) => (
          <ModuleCard key={m.key} {...m} score={data.modules[m.key]} />
        ))}
      </div>

      <div style={{ height: 24 }} />
      <SectionTitle title="Cyber Defense" />
      <div className="defense-grid">
        {DEFENSE.map((d) => (
          <DefenseTile key={d.label} {...d} />
        ))}
      </div>

      {data.trend?.length > 0 && (
        <>
          <div style={{ height: 24 }} />
          <SectionTitle title="7-Day Security Score" />
          <div className="pad">
            <ScoreChart points={data.trend} />
          </div>
        </>
      )}

      <div style={{ height: 24 }} />
      <SectionTitle title="Scan History" actionLabel="See All" actionTo="/phishing" />
      {weekScans.length === 0 ? (
        <div className="pad">
          <div className="card">
            <EmptyState
              title="Nothing scanned yet"
              hint="Paste a link into the Phishing scanner to get started."
            />
          </div>
        </div>
      ) : (
        <WeekScanHistory scans={weekScans} />
      )}
    </>
  );
}
