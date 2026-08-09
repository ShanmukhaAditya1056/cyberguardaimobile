import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

import { api } from '../lib/api.js';
import {
  Banner,
  EmptyState,
  RiskBadge,
  ScoreRing,
  Spinner,
  formatDate,
  scoreColor,
} from '../components/ui.jsx';

const MODULES = [
  { key: 'phishing', label: 'Phishing', to: '/phishing' },
  { key: 'malware', label: 'App Scanner', to: '/malware' },
  { key: 'breach', label: 'Breach Monitor', to: '/breach' },
  { key: 'wifi', label: 'Wi-Fi Safety', to: '/wifi' },
];

/** Sparkline of the 7-day score trend. */
function Trend({ points }) {
  if (points.length < 2) {
    return (
      <p className="muted">
        Run scans on two or more days to see a trend here.
      </p>
    );
  }

  const width = 320;
  const height = 70;
  const step = width / (points.length - 1);
  const path = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${i * step} ${height - (p.score / 100) * height}`)
    .join(' ');
  const latest = points[points.length - 1].score;

  return (
    <svg
      width="100%"
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      preserveAspectRatio="none"
      role="img"
      aria-label={`Security score over the last ${points.length} days, currently ${latest} out of 100`}
    >
      <path d={path} fill="none" stroke={scoreColor(latest)} strokeWidth="2.5" />
    </svg>
  );
}

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [health, setHealth] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api.dashboard.summary().then(setData).catch((e) => setError(e.message));
    // Best-effort: the banner it feeds is informational, so a failure here
    // must not stop the dashboard rendering.
    api.health().then(setHealth).catch(() => {});
  }, []);

  if (error) return <Banner kind="error">{error}</Banner>;
  if (!data) return <Spinner />;

  const degraded = health
    ? Object.entries(health.engines).filter(([, ok]) => !ok).map(([name]) => name)
    : [];

  return (
    <>
      <h1>Security overview</h1>

      {degraded.length > 0 && (
        <Banner kind="warn">
          These models could not be loaded on the server:{' '}
          <strong>{degraded.join(', ')}</strong>. The affected scanners are
          still running, using their rules engines only — verdicts will be less
          precise than on the mobile app.
        </Banner>
      )}

      <div className="card">
        <ScoreRing score={data.score} label={data.label} />
        <p className="muted" style={{ marginTop: 14, marginBottom: 0 }}>
          {data.labelVerbose}
          {data.lastScanAt && ` · last scan ${formatDate(data.lastScanAt)}`}
        </p>
      </div>

      <div className="grid">
        {MODULES.map((m) => {
          const score = data.modules[m.key];
          return (
            <Link
              key={m.key}
              to={m.to}
              className="card"
              style={{ textDecoration: 'none', color: 'inherit', marginBottom: 0 }}
            >
              <div className="spread">
                <h3 style={{ margin: 0 }}>{m.label}</h3>
                <strong style={{ color: scoreColor(score) }}>{score}</strong>
              </div>
              <div className="muted" style={{ marginTop: 6 }}>
                {data.scanCounts?.[m.key] ?? 0} scan
                {(data.scanCounts?.[m.key] ?? 0) === 1 ? '' : 's'} recorded
              </div>
            </Link>
          );
        })}
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <h2>7-day trend</h2>
        <Trend points={data.trend} />
      </div>

      <div className="card">
        <div className="spread">
          <h2 style={{ margin: 0 }}>Recent scans</h2>
          <Link to="/alerts">
            {data.unreadAlerts > 0
              ? `${data.unreadAlerts} unread alert${data.unreadAlerts === 1 ? '' : 's'}`
              : 'Alerts'}
          </Link>
        </div>
        {data.recentScans.length === 0 ? (
          <EmptyState
            title="Nothing scanned yet"
            hint="Paste a link into the Phishing scanner to get started."
          />
        ) : (
          <ul className="list">
            {data.recentScans.map((scan) => (
              <li key={scan._id}>
                <div style={{ minWidth: 0 }}>
                  <div className="mono">{scan.input}</div>
                  <div className="muted">
                    {scan.type} · {formatDate(scan.createdAt)}
                  </div>
                </div>
                <RiskBadge
                  level={
                    scan.verdict === 'safe' || scan.verdict === 'clean'
                      ? 'safe'
                      : scan.verdict === 'low' || scan.verdict === 'medium'
                        ? scan.verdict
                        : 'critical'
                  }
                />
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
