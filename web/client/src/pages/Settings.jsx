import { useEffect, useState } from 'react';

import { useAuth } from '../context/AuthContext.jsx';
import { api } from '../lib/api.js';
import { Banner, Spinner } from '../components/ui.jsx';

const LOCALES = [
  { value: 'en', label: 'English' },
  { value: 'hi', label: 'हिन्दी' },
  { value: 'ta', label: 'தமிழ்' },
  { value: 'te', label: 'తెలుగు' },
];

export default function Settings() {
  const { user, updateSettings } = useAuth();
  const [health, setHealth] = useState(null);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [confirmingClear, setConfirmingClear] = useState(false);

  useEffect(() => {
    api.health().then(setHealth).catch(() => {});
  }, []);

  const change = async (patch) => {
    setError('');
    setMessage('');
    try {
      await updateSettings(patch);
      setMessage('Saved.');
    } catch (err) {
      setError(err.message);
    }
  };

  const clearHistory = async () => {
    setBusy(true);
    setError('');
    try {
      const res = await api.dashboard.clearHistory();
      setMessage(
        `Deleted ${res.deleted.scans} scans, ${res.deleted.alerts} alerts and ` +
          `${res.deleted.scoreEntries} score entries.`,
      );
      setConfirmingClear(false);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <h1>Settings</h1>

      <Banner kind="error">{error}</Banner>
      <Banner kind="info">{message}</Banner>

      <div className="card">
        <h2>Account</h2>
        <p className="mono">{user?.email}</p>
        <p className="muted" style={{ marginBottom: 0 }}>
          Member since {new Date(user?.createdAt).toLocaleDateString()}
        </p>
      </div>

      <div className="card">
        <h2>Preferences</h2>

        <div className="field">
          <label htmlFor="locale">Language</label>
          <select
            id="locale"
            value={user?.settings?.locale ?? 'en'}
            onChange={(e) => change({ locale: e.target.value })}
          >
            {LOCALES.map((l) => (
              <option key={l.value} value={l.value}>
                {l.label}
              </option>
            ))}
          </select>
          <div className="hint">
            Stored on your account and used by the mobile app. This web UI is
            English-only for now.
          </div>
        </div>

        <div className="field">
          <label htmlFor="saveHistory">Save scan history</label>
          <select
            id="saveHistory"
            value={user?.settings?.saveScanHistory === false ? 'off' : 'on'}
            onChange={(e) => change({ saveScanHistory: e.target.value === 'on' })}
          >
            <option value="on">On — keep a record of every scan</option>
            <option value="off">Off — scan without storing anything</option>
          </select>
          <div className="hint">
            With this off, scans still run and still return full verdicts —
            nothing is written to the database. History is kept for 90 days
            either way.
          </div>
        </div>
      </div>

      <div className="card">
        <h2>Detection engines</h2>
        <p className="muted">
          Which models this server loaded. Anything missing means that scanner
          falls back to its rules engine.
        </p>
        {!health ? (
          <Spinner />
        ) : (
          <ul className="list">
            {Object.entries(health.engines).map(([name, ok]) => (
              <li key={name}>
                <span>{name}</span>
                <span className={`badge ${ok ? 'safe' : 'warning'}`}>
                  {ok ? 'loaded' : 'missing'}
                </span>
              </li>
            ))}
            <li>
              <span>HIBP API key</span>
              <span className={`badge ${health.hibpKeyConfigured ? 'safe' : 'info'}`}>
                {health.hibpKeyConfigured ? 'configured' : 'offline mode'}
              </span>
            </li>
          </ul>
        )}
        {health?.modelErrors?.length > 0 && (
          <Banner kind="warn">{health.modelErrors.join('; ')}</Banner>
        )}
      </div>

      <div className="card">
        <h2>Your data</h2>
        <p>
          Deletes every scan, alert and score entry on this account. Your
          account itself is kept.
        </p>
        {confirmingClear ? (
          <div className="row">
            <button type="button" className="danger" onClick={clearHistory} disabled={busy}>
              {busy ? <Spinner /> : 'Yes, delete everything'}
            </button>
            <button
              type="button"
              className="secondary"
              onClick={() => setConfirmingClear(false)}
            >
              Cancel
            </button>
          </div>
        ) : (
          <button
            type="button"
            className="danger"
            onClick={() => setConfirmingClear(true)}
          >
            Clear all history
          </button>
        )}
      </div>
    </>
  );
}
