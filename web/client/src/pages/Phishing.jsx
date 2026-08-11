import { useCallback, useEffect, useState } from 'react';

import { api } from '../lib/api.js';
import { Icon } from '../components/icons.jsx';
import {
  Banner,
  EmptyState,
  PageHeader,
  RiskBadge,
  ShapBars,
  Spinner,
  Tabs,
  formatDate,
} from '../components/ui.jsx';

/** URL and pasted-message tabs — same engine, two input shapes. */
const TABS = [
  { key: 'url', label: 'URL scanner' },
  { key: 'text', label: 'Message scanner' },
];

function Verdict({ result }) {
  return (
    <div className={`verdict ${result.isPhishing ? 'phishing' : 'safe'}`}>
      <h2>{result.isPhishing ? 'Phishing' : 'Looks safe'}</h2>
      <div className="mono" style={{ marginBottom: 10 }}>{result.url}</div>
      <p style={{ marginBottom: 14 }}>
        <strong>{result.confidence}% confidence</strong>
        {result.mlAvailable ? (
          <span className="muted">
            {' '}· rules engine blended with the trained model (p=
            {result.mlProbability})
          </span>
        ) : (
          <span className="muted"> · rules engine only</span>
        )}
      </p>

      <ShapBars reasons={result.shapReasons} />

      {result.triggeredRules.length > 0 && (
        <details style={{ marginTop: 12 }}>
          <summary style={{ cursor: 'pointer', fontWeight: 700 }}>
            {result.triggeredRules.length} rule
            {result.triggeredRules.length === 1 ? '' : 's'} triggered
          </summary>
          <ul style={{ marginTop: 8, paddingLeft: 20 }}>
            {result.triggeredRules.map((rule) => (
              <li key={rule}>{rule}</li>
            ))}
          </ul>
        </details>
      )}
    </div>
  );
}

export default function Phishing() {
  const [tab, setTab] = useState('url');
  const [url, setUrl] = useState('');
  const [text, setText] = useState('');
  const [result, setResult] = useState(null);
  const [textResult, setTextResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const loadHistory = useCallback(() => {
    api.phishing.history().then((r) => setHistory(r.scans)).catch(() => {});
  }, []);

  useEffect(loadHistory, [loadHistory]);

  const scanUrl = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    setTextResult(null);
    try {
      const res = await api.phishing.scan(url);
      setResult(res.result);
      loadHistory();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const scanText = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    setResult(null);
    try {
      const res = await api.phishing.scanText(text);
      setTextResult(res);
      loadHistory();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const remove = async (id) => {
    await api.phishing.remove(id);
    loadHistory();
  };

  return (
    <>
      <PageHeader title="Phishing Scanner" />
      <Tabs tabs={TABS} active={tab} onSelect={setTab} />

      <div className="pad">
      <p className="muted" style={{ marginBottom: 16 }}>
        Twelve rules plus a trained classifier, the same engine the mobile app
        runs on-device. Nothing you scan is sent anywhere beyond your own
        CyberGuard server.
      </p>

      <Banner kind="error">{error}</Banner>

      <div className="card">
        {tab === 'url' ? (
          <form onSubmit={scanUrl}>
            <div className="field">
              <label htmlFor="url">URL to check</label>
              <input
                id="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="paytm-verify.tk/kyc-update"
                required
                // A URL is not prose: autocorrect and capitalisation would
                // silently alter what gets scanned.
                autoCapitalize="none"
                autoCorrect="off"
                spellCheck="false"
              />
              <div className="hint">
                The scheme is optional — https:// is assumed.
              </div>
            </div>
            <button type="submit" className="block" disabled={busy}>
              {busy ? <Spinner /> : 'Scan link'}
            </button>
          </form>
        ) : (
          <form onSubmit={scanText}>
            <div className="field">
              <label htmlFor="text">Paste an SMS or email</label>
              <textarea
                id="text"
                value={text}
                onChange={(e) => setText(e.target.value)}
                placeholder="Dear customer, your KYC is pending. Verify at http://sbi-verify.tk/update"
                required
              />
              <div className="hint">
                Every link in the message is extracted and scanned. This is the
                browser's stand-in for the app's live SMS guard, which no web
                page can do on its own.
              </div>
            </div>
            <button type="submit" className="block" disabled={busy}>
              {busy ? <Spinner /> : 'Scan message'}
            </button>
          </form>
        )}
      </div>

      {result && <Verdict result={result} />}

      {textResult && (
        <div className="card">
          <h2>
            {textResult.urlsFound} link
            {textResult.urlsFound === 1 ? '' : 's'} found
          </h2>
          {textResult.urlsFound === 0 ? (
            <p className="muted">No links in that message.</p>
          ) : (
            <div className="stack">
              {textResult.results.map((r) => (
                <Verdict key={r.url} result={r} />
              ))}
            </div>
          )}
        </div>
      )}

      <div className="card">
        <h2>Scan History</h2>
        {history.length === 0 ? (
          <EmptyState title="No phishing scans yet" />
        ) : (
          <ul className="list">
            {history.map((scan) => (
              <li key={scan._id} className="scan-row">
                <div className="scan-body">
                  <span className="mono">{scan.input}</span>
                  <div className="hint">
                    {scan.confidence}% confidence · {formatDate(scan.createdAt)}
                  </div>
                </div>
                <div className="scan-verdict">
                  <RiskBadge level={scan.verdict} />
                </div>
                <button
                  type="button"
                  className="icon-btn"
                  aria-label={`Delete the scan of ${scan.input}`}
                  title="Delete"
                  onClick={() => remove(scan._id)}
                >
                  <Icon name="delete_outline" size={16} />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
      </div>
    </>
  );
}
