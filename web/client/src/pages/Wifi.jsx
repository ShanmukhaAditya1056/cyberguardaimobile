import { useEffect, useState } from 'react';

import { api } from '../lib/api.js';
import {
  Banner,
  CheckList,
  EmptyState,
  PageHeader,
  RiskBadge,
  ScoreRing,
  Spinner,
  formatDate,
} from '../components/ui.jsx';

const SECURITY_OPTIONS = [
  'WPA3',
  'WPA2',
  'WPA',
  'WEP',
  'Open',
];

export default function Wifi() {
  const [form, setForm] = useState({
    ssid: '',
    bssid: '',
    rssi: -60,
    security: 'WPA2',
    frequency: 2437,
  });
  const [result, setResult] = useState(null);
  const [known, setKnown] = useState([]);
  const [history, setHistory] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const refresh = () => {
    api.wifi.knownNetworks().then((r) => setKnown(r.networks)).catch(() => {});
    api.wifi.history().then((r) => setHistory(r.scans)).catch(() => {});
  };

  useEffect(refresh, []);

  const set = (key) => (event) => {
    const raw = event.target.value;
    setForm((f) => ({
      ...f,
      [key]: key === 'rssi' || key === 'frequency' ? Number(raw) : raw,
    }));
  };

  const analyze = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      const payload = { ...form };
      // The server rejects a malformed MAC, so an empty field must be omitted
      // rather than sent as ''.
      if (!payload.bssid) delete payload.bssid;
      const res = await api.wifi.analyze(payload);
      setResult(res.result);
      refresh();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const forget = async (id) => {
    await api.wifi.forget(id);
    refresh();
  };

  return (
    <>
      <PageHeader title="Wi-Fi Scanner" />
      <div className="pad">
      <p className="muted">
        A web page cannot read the network it is connected to — no browser
        exposes the SSID, signal or cipher. Enter what the network advertises
        (from the café's sign, or your phone's network details) and the same
        rules and Isolation Forest the app runs will score it.
      </p>

      <Banner kind="error">{error}</Banner>

      <form className="card" onSubmit={analyze}>
        <div className="grid">
          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="ssid">Network name (SSID)</label>
            <input
              id="ssid"
              value={form.ssid}
              onChange={set('ssid')}
              required
              placeholder="Airport_Free_WiFi"
            />
          </div>

          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="bssid">Access point MAC (BSSID)</label>
            <input
              id="bssid"
              value={form.bssid}
              onChange={set('bssid')}
              placeholder="a4:2b:8c:00:1f:3e"
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck="false"
            />
            <div className="hint">
              Optional, but this is what powers the Evil Twin check — a fake
              access point can copy a name, not the real hardware's MAC.
            </div>
          </div>

          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="security">Security</label>
            <select id="security" value={form.security} onChange={set('security')}>
              {SECURITY_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>

          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="rssi">Signal strength: {form.rssi} dBm</label>
            <input
              id="rssi"
              type="range"
              min="-100"
              max="-20"
              value={form.rssi}
              onChange={set('rssi')}
            />
            <div className="hint">-50 is excellent, below -80 is weak.</div>
          </div>

          <div className="field" style={{ marginBottom: 0 }}>
            <label htmlFor="frequency">Band</label>
            <select id="frequency" value={form.frequency} onChange={set('frequency')}>
              <option value={2437}>2.4 GHz</option>
              <option value={5180}>5 GHz</option>
              <option value={5955}>6 GHz</option>
            </select>
          </div>
        </div>

        <button type="submit" disabled={busy} style={{ marginTop: 16 }}>
          {busy ? <Spinner /> : 'Analyse network'}
        </button>
      </form>

      {result && (
        <div className="card">
          <div className="spread" style={{ marginBottom: 14 }}>
            <h2 style={{ margin: 0 }}>{result.ssid}</h2>
            <RiskBadge level={result.riskLevel} />
          </div>

          <ScoreRing score={result.trustScore} label="TRUST" size={100} />

          <div style={{ marginTop: 18 }}>
            <CheckList checks={result.checks} />
          </div>

          {!result.dnsMeasured && (
            <p className="muted" style={{ marginTop: 12, marginBottom: 0 }}>
              The DNS-health and latency checks the mobile app measures directly
              have no browser equivalent, so they are not part of this score.
            </p>
          )}
          {!result.mlAvailable && (
            <p className="muted" style={{ marginBottom: 0 }}>
              Isolation Forest model unavailable — scored on rules alone.
            </p>
          )}
        </div>
      )}

      <div className="card">
        <h2>Known networks</h2>
        <p className="muted">
          The access point address last seen for each network. A change here is
          what raises the Evil Twin warning.
        </p>
        {known.length === 0 ? (
          <EmptyState title="No networks recorded yet" />
        ) : (
          <ul className="list">
            {known.map((n) => (
              <li key={n._id}>
                <div>
                  <strong>{n.ssid}</strong>
                  <div className="mono muted">{n.bssid}</div>
                </div>
                <button type="button" className="link" onClick={() => forget(n._id)}>
                  Forget
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="card">
        <h2>History</h2>
        {history.length === 0 ? (
          <EmptyState title="No Wi-Fi scans yet" />
        ) : (
          <ul className="list">
            {history.map((scan) => (
              <li key={scan._id}>
                <div>
                  <strong>{scan.input}</strong>
                  <div className="muted">
                    trust {scan.confidence}/100 · {formatDate(scan.createdAt)}
                  </div>
                </div>
                <RiskBadge level={scan.verdict} />
              </li>
            ))}
          </ul>
        )}
      </div>
      </div>
    </>
  );
}
