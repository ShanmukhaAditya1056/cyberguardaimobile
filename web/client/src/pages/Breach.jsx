import { useEffect, useState } from 'react';

import { api } from '../lib/api.js';
import { splitForRangeQuery } from '../lib/kAnonymity.js';
import {
  Banner,
  EmptyState,
  PageHeader,
  Spinner,
  formatDate,
} from '../components/ui.jsx';

export default function Breach() {
  const [tab, setTab] = useState('password');
  const [password, setPassword] = useState('');
  const [email, setEmail] = useState('');
  const [passwordResult, setPasswordResult] = useState(null);
  const [accountResult, setAccountResult] = useState(null);
  const [history, setHistory] = useState([]);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    api.breach.history().then((r) => setHistory(r.scans)).catch(() => {});
  }, []);

  const refresh = () =>
    api.breach.history().then((r) => setHistory(r.scans)).catch(() => {});

  const checkPassword = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    setAccountResult(null);
    try {
      // The hash is computed and split here, in the browser. Only the
      // 5-character prefix is sent — see lib/kAnonymity.js.
      const { prefix, suffix } = await splitForRangeQuery(password);
      const res = await api.breach.password(prefix, suffix);
      setPasswordResult(res);
      // Cleared immediately: there is no reason for it to stay in component
      // state, in the DOM, or in a React DevTools snapshot afterwards.
      setPassword('');
      refresh();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const checkAccount = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    setPasswordResult(null);
    try {
      const res = await api.breach.account(email);
      setAccountResult(res);
      refresh();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader title="Breach Monitor" />
      <div className="pad">

      <Banner kind="info">
        Your password is hashed in this browser and only the first five
        characters of that hash are ever sent — the same k-anonymity protocol
        the mobile app uses. Neither the CyberGuard server nor Have I Been
        Pwned ever receives the password itself.
      </Banner>

      <div className="chips" style={{ marginBottom: 16 }}>
        <button
          type="button"
          className={`chip ${tab === 'password' ? 'on' : ''}`}
          onClick={() => setTab('password')}
        >
          Password
        </button>
        <button
          type="button"
          className={`chip ${tab === 'account' ? 'on' : ''}`}
          onClick={() => setTab('account')}
        >
          Email address
        </button>
      </div>

      <Banner kind="error">{error}</Banner>

      <div className="card">
        {tab === 'password' ? (
          <form onSubmit={checkPassword}>
            <div className="field">
              <label htmlFor="password">Password to check</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="off"
              />
            </div>
            <button type="submit" disabled={busy}>
              {busy ? <Spinner /> : 'Check password'}
            </button>
          </form>
        ) : (
          <form onSubmit={checkAccount}>
            <div className="field">
              <label htmlFor="email">Email address</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
              <div className="hint">
                Account lookups have no k-anonymity equivalent, so the address
                is sent to your CyberGuard server for the lookup. Only its
                masked form and hash prefix are stored.
              </div>
            </div>
            <button type="submit" disabled={busy}>
              {busy ? <Spinner /> : 'Check address'}
            </button>
          </form>
        )}
      </div>

      {passwordResult && (
        <div className={`verdict ${passwordResult.isBreached ? 'phishing' : 'safe'}`}>
          <h2>
            {passwordResult.isBreached
              ? 'Found in known breaches'
              : 'Not found in known breaches'}
          </h2>
          {passwordResult.isBreached ? (
            <p style={{ marginBottom: 0 }}>
              This password appears{' '}
              <strong>{passwordResult.count.toLocaleString()}</strong> time
              {passwordResult.count === 1 ? '' : 's'} in breach corpora. Change
              it anywhere you have used it, and do not reuse it.
            </p>
          ) : (
            <p style={{ marginBottom: 0 }}>
              This password does not appear in HIBP's corpus. That is not a
              guarantee it is strong — only that it has not turned up in a
              breach yet.
            </p>
          )}
        </div>
      )}

      {accountResult && (
        <div className={`verdict ${accountResult.isBreached ? 'phishing' : 'safe'}`}>
          <h2>
            {accountResult.isBreached
              ? `Found in ${accountResult.breachCount} breach${accountResult.breachCount === 1 ? '' : 'es'}`
              : 'No breaches found'}
          </h2>
          <p className="mono">{accountResult.maskedEmail}</p>

          {accountResult.source === 'offline' && (
            <Banner kind="warn">
              Offline dataset — no HIBP API key is configured on this server.
              These are real historical breaches, but which of them this
              address is matched to is derived from a hash, not from a live
              lookup. Set HIBP_API_KEY for a genuine result.
            </Banner>
          )}

          {accountResult.breaches.length > 0 && (
            <ul className="list" style={{ marginTop: 12 }}>
              {accountResult.breaches.map((b) => (
                <li key={b.name} style={{ display: 'block' }}>
                  <strong>{b.title}</strong>{' '}
                  <span className="muted">
                    {b.breachDate} · {Number(b.pwnCount).toLocaleString()} accounts
                  </span>
                  <div style={{ marginTop: 4 }}>{b.description}</div>
                  <div className="muted" style={{ marginTop: 4 }}>
                    Exposed: {b.dataClasses.join(', ')}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <div className="card">
        <h2>History</h2>
        {history.length === 0 ? (
          <EmptyState
            title="No breach checks yet"
            hint="Only the hash prefix of anything you check is stored."
          />
        ) : (
          <ul className="list">
            {history.map((scan) => (
              <li key={scan._id}>
                <div>
                  <span className="mono">{scan.input}…</span>
                  <div className="muted">
                    {scan.details?.kind ?? 'check'} · {formatDate(scan.createdAt)}
                  </div>
                </div>
                <span className={`badge ${scan.verdict === 'safe' ? 'safe' : 'critical'}`}>
                  {scan.verdict}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
      </div>
    </>
  );
}
