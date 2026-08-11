import { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';

import { api } from '../lib/api.js';
import {
  Banner,
  EmptyState,
  PageHeader,
  RiskBadge,
  ScoreRing,
  Spinner,
  Tabs,
  formatDate,
} from '../components/ui.jsx';

/**
 * The four proactive-defence features, ported from the app's `/fusion`,
 * `/arbitration`, `/risk` and `/screenshot` screens.
 */

const TABS = [
  { id: 'fusion', label: 'Threat Fusion' },
  { id: 'risk', label: 'Predictive Risk' },
  { id: 'arbitration', label: 'Arbitration Log' },
  { id: 'message', label: 'Scam Message' },
];

// The engines emit stable identifiers rather than prose so the app can
// localise them; the web UI is English-only, so it maps them here.
const FACTOR_LABEL = {
  phishing: 'Phishing links encountered',
  sms: 'Suspicious messages',
  wifi: 'Untrusted Wi-Fi networks',
  malware: 'Risky apps found',
  interceptor: 'Links blocked',
  breach: 'Credentials exposed in a breach',
  trend: 'Security score declining',
};

const CATEGORY_LABEL = {
  phishing: 'Phishing',
  credentialTheft: 'Credential theft',
  malware: 'Malware',
};

const RECOMMENDATION = {
  breach: 'Change the passwords on any account using exposed credentials, and turn on two-factor authentication.',
  phishing: 'Treat unexpected links with suspicion — check the domain before signing in anywhere.',
  wifi: 'Avoid signing in to banking or email on open networks.',
  malware: 'Review the apps flagged by the scanner and remove any you do not recognise.',
  interceptor: 'Links are being blocked for you — worth checking where they are coming from.',
  healthy: 'Nothing to act on. Keep scanning links you were not expecting.',
};

const SCAM_CATEGORY = {
  fakeBank: 'Fake bank page',
  fakeUpi: 'Fake UPI request',
  fakeOtp: 'OTP harvesting',
  fakeLogin: 'Fake login page',
  fakeKyc: 'Fake KYC demand',
  fakeLottery: 'Lottery / prize scam',
  fakeInvestment: 'Investment scam',
  fakeSupport: 'Fake support desk',
  none: 'No specific category',
};

const SCAM_REASON = {
  categoryHit: (r) => `${SCAM_CATEGORY[r.category]} — matched “${r.matched}”`,
  brand: (r) => `References the brand “${r.matched}”`,
  urgency: (r) => `Pressure wording — “${r.matched}”`,
  noIndicators: () => 'No scam indicators found',
  noText: () => 'No readable text supplied',
};

const bandColor = (band) =>
  band === 'high' ? 'var(--sev-high)' : band === 'medium' ? 'var(--sev-medium)' : 'var(--sev-low)';

function FusionTab() {
  const [url, setUrl] = useState('');
  const [cloudIntel, setCloudIntel] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      const res = await api.defense.fusionScan(url, cloudIntel);
      setResult(res.result);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <p className="muted">
        Runs several detection sources over one link and reconciles them. A
        sufficiently trusted source that flags a URL can overrule a clean local
        verdict — and when that happens, it is recorded in the Arbitration Log.
      </p>

      <Banner kind="error">{error}</Banner>

      <form className="card" onSubmit={submit}>
        <div className="field">
          <label htmlFor="fusion-url">URL to check</label>
          <input
            id="fusion-url"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="sbi-secure-login.top/verify"
            required
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck="false"
          />
        </div>
        <div className="field">
          <label htmlFor="cloud">External reputation feeds</label>
          <select
            id="cloud"
            value={cloudIntel ? 'on' : 'off'}
            onChange={(e) => setCloudIntel(e.target.value === 'on')}
          >
            <option value="off">Off — on-device engine only</option>
            <option value="on">On — also consult reputation feeds</option>
          </select>
          <div className="hint">
            Off by default, mirroring the app's cloud-intel opt-in. With it off,
            only CyberGuard's own engine votes.
          </div>
        </div>
        <button type="submit" disabled={busy}>
          {busy ? <Spinner /> : 'Run fusion'}
        </button>
      </form>

      {result && (
        <div className="card">
          <div className="spread">
            <h2 style={{ margin: 0 }}>
              {result.action === 'block'
                ? 'Blocked'
                : result.action === 'warn'
                  ? 'Warning'
                  : 'Allowed'}
            </h2>
            <RiskBadge level={result.level === 'safe' ? 'safe' : result.level === 'suspicious' ? 'medium' : result.level === 'dangerous' ? 'high' : 'critical'} />
          </div>
          <div className="mono" style={{ margin: '8px 0 14px' }}>{result.url}</div>

          <ScoreRing score={result.unifiedScore} label="THREAT" size={100} />

          <p style={{ marginTop: 14 }}>
            Agreement confidence <strong>{Math.round(result.confidence * 100)}%</strong>
            {result.hasConflict && (
              <span className="muted"> · sources disagreed</span>
            )}
          </p>

          {result.overrideApplied && (
            <Banner kind="warn">{result.overrideReason}</Banner>
          )}

          <h3 style={{ marginTop: 16 }}>Source verdicts</h3>
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Source</th>
                  <th>Trust</th>
                  <th>Score</th>
                  <th>Confidence</th>
                  <th>Reason</th>
                </tr>
              </thead>
              <tbody>
                {result.verdicts.map((v) => (
                  <tr key={v.sourceName}>
                    <td>{v.sourceName}</td>
                    <td>{v.trustWeight}</td>
                    <td>{v.maliciousScore}</td>
                    <td>{Math.round(v.confidence * 100)}%</td>
                    <td>{v.reasons[0]}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </>
  );
}

function RiskTab() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api.defense.risk().then(setData).catch((e) => setError(e.message));
  }, []);

  if (error) return <Banner kind="error">{error}</Banner>;
  if (!data) return <Spinner />;

  const { assessment, signals } = data;

  return (
    <>
      <p className="muted">
        How likely you are to be targeted, based on your own last 7 days. Note
        this runs the opposite way to the security score: <strong>higher is
        worse</strong>.
      </p>

      <div className="card">
        <ScoreRing
          score={assessment.riskScore}
          label={assessment.band.toUpperCase()}
          size={120}
        />
        <p className="muted" style={{ marginTop: 12, marginBottom: 0 }}>
          Generated {formatDate(assessment.generatedAt)}
        </p>
      </div>

      <div className="card">
        <h2>What is driving this</h2>
        {assessment.factors.length === 0 ? (
          <EmptyState
            title="No risk factors in the last 7 days"
            hint="Nothing you have scanned recently suggests you are being targeted."
          />
        ) : (
          <ul className="list">
            {assessment.factors.map((f) => (
              <li key={f.type}>
                <div>
                  <strong>{FACTOR_LABEL[f.type] ?? f.type}</strong>
                  {f.value > 0 && <div className="muted">{f.value} in the last 7 days</div>}
                </div>
                <span className="badge high">+{f.contribution}</span>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="card">
        <h2>Forecast</h2>
        <div className="grid">
          {assessment.forecast.map((f) => (
            <div key={f.category}>
              <div className="muted">{CATEGORY_LABEL[f.category] ?? f.category}</div>
              <strong style={{ fontSize: '1.2rem', color: bandColor(f.likelihood) }}>
                {f.likelihood.toUpperCase()}
              </strong>
            </div>
          ))}
        </div>
      </div>

      <div className="card">
        <h2>What to do</h2>
        <ul className="list">
          {assessment.recommendations.map((r) => (
            <li key={r}>
              <span>{RECOMMENDATION[r] ?? r}</span>
            </li>
          ))}
        </ul>
      </div>

      <details className="card">
        <summary style={{ cursor: 'pointer', fontWeight: 700 }}>
          Signals this was computed from
        </summary>
        <ul className="list" style={{ marginTop: 10 }}>
          {Object.entries(signals).map(([k, v]) => (
            <li key={k}>
              <span className="muted">{k}</span>
              <span>{String(v)}</span>
            </li>
          ))}
        </ul>
        <p className="muted" style={{ marginTop: 10, marginBottom: 0 }}>
          `suspiciousSms` is always zero here — a web page can never be handed
          incoming messages.
        </p>
      </details>
    </>
  );
}

function ArbitrationTab() {
  const [data, setData] = useState(null);
  const [conflictsOnly, setConflictsOnly] = useState(false);
  const [error, setError] = useState('');

  const load = useCallback(() => {
    api.defense
      .arbitration(conflictsOnly)
      .then(setData)
      .catch((e) => setError(e.message));
  }, [conflictsOnly]);

  useEffect(load, [load]);

  const remove = async (id) => {
    await api.defense.removeArbitration(id);
    load();
  };

  return (
    <>
      <p className="muted">
        Every fusion run where the detectors contradicted each other, or where a
        trusted feed overruled the local model. This is what makes an automated
        override auditable rather than something you take on faith.
      </p>

      <Banner kind="error">{error}</Banner>

      <div className="chips" style={{ marginBottom: 16 }}>
        <button
          type="button"
          className={`chip ${!conflictsOnly ? 'on' : ''}`}
          onClick={() => setConflictsOnly(false)}
        >
          All entries
        </button>
        <button
          type="button"
          className={`chip ${conflictsOnly ? 'on' : ''}`}
          onClick={() => setConflictsOnly(true)}
        >
          Conflicts only
        </button>
      </div>

      {!data ? (
        <Spinner />
      ) : (
        <>
          <div className="card">
            <div className="row">
              <div>
                <div className="muted">Entries</div>
                <strong style={{ fontSize: '1.3rem' }}>{data.summary.total}</strong>
              </div>
              <div style={{ marginLeft: 24 }}>
                <div className="muted">Conflicts</div>
                <strong style={{ fontSize: '1.3rem', color: 'var(--sev-medium)' }}>
                  {data.summary.conflicts}
                </strong>
              </div>
              <div style={{ marginLeft: 24 }}>
                <div className="muted">Overrides</div>
                <strong style={{ fontSize: '1.3rem', color: 'var(--sev-critical)' }}>
                  {data.summary.overrides}
                </strong>
              </div>
            </div>
          </div>

          <div className="card">
            {data.entries.length === 0 ? (
              <EmptyState
                title="No disagreements recorded"
                hint="Unanimous verdicts are not logged — only the disputed ones."
              />
            ) : (
              <ul className="list">
                {data.entries.map((e) => (
                  <li key={e._id}>
                    <div style={{ minWidth: 0 }}>
                      <div className="mono">{e.url}</div>
                      <div className="muted" style={{ marginTop: 4 }}>
                        {e.level} · {e.action} · score {e.unifiedScore} ·{' '}
                        {formatDate(e.createdAt)}
                      </div>
                      {e.overrideApplied && (
                        <div style={{ marginTop: 6, color: 'var(--sev-critical)' }}>
                          {e.overrideReason}
                        </div>
                      )}
                      {e.hasConflict && (
                        <div className="muted" style={{ marginTop: 4 }}>
                          {e.verdicts?.length ?? 0} sources, not unanimous
                        </div>
                      )}
                    </div>
                    <button type="button" className="link" onClick={() => remove(e._id)}>
                      Delete
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </>
      )}
    </>
  );
}

function MessageTab() {
  const [text, setText] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      const res = await api.defense.classifyText(text);
      setResult(res.result);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <p className="muted">
        The mobile app reads text out of a screenshot with on-device OCR. No
        browser can do that, and uploading screenshots to a cloud OCR service
        would defeat the point — so paste the text instead. The classifier that
        scores it is the same one.
      </p>

      <Banner kind="error">{error}</Banner>

      <form className="card" onSubmit={submit}>
        <div className="field">
          <label htmlFor="msg">Message or page text</label>
          <textarea
            id="msg"
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Congratulations! You have won ₹25,00,000. Share OTP to claim your prize immediately."
            required
          />
        </div>
        <button type="submit" disabled={busy}>
          {busy ? <Spinner /> : 'Classify text'}
        </button>
      </form>

      {result && (
        <div className={`verdict ${result.isScam ? 'phishing' : 'safe'}`}>
          <h2>{result.isScam ? 'Likely a scam' : 'No scam indicators'}</h2>
          <p>
            <strong>{result.scamProbability}% scam probability</strong>
            {result.category !== 'none' && (
              <span className="muted"> · {SCAM_CATEGORY[result.category]}</span>
            )}
            {result.detectedBrand && (
              <span className="muted"> · references “{result.detectedBrand}”</span>
            )}
          </p>
          <ul className="list">
            {result.reasons.map((r, i) => (
              <li key={`${r.type}-${i}`} style={{ display: 'block' }}>
                {(SCAM_REASON[r.type] ?? (() => r.type))(r)}
              </li>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}

/**
 * The app gives each of these four features its own route, reached from the
 * Cyber Defense grid. Here they are tabs on one page, so the grid's tiles pass
 * `?tab=` to land on the right one — a tile that always opened Threat Fusion
 * would make three of the four unreachable from the dashboard.
 */
export default function Defense() {
  const [params, setParams] = useSearchParams();
  const requested = params.get('tab');
  const tab = TABS.some((t) => t.id === requested) ? requested : 'fusion';

  const select = (id) => setParams(id === 'fusion' ? {} : { tab: id }, { replace: true });

  return (
    <>
      <PageHeader title={TABS.find((t) => t.id === tab).label} />
      <Tabs
        tabs={TABS.map((t) => ({ key: t.id, label: t.label }))}
        active={tab}
        onSelect={select}
      />

      <div className="pad">
        {tab === 'fusion' && <FusionTab />}
        {tab === 'risk' && <RiskTab />}
        {tab === 'arbitration' && <ArbitrationTab />}
        {tab === 'message' && <MessageTab />}
      </div>
    </>
  );
}
