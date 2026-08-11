import { useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';

import { useAuth } from '../context/AuthContext.jsx';
import { Banner, Spinner } from '../components/ui.jsx';
import { Icon } from '../components/icons.jsx';

/**
 * Sign-in.
 *
 * Two shapes, decided by whether Firebase is configured on both this client
 * and the API (`authMode` in AuthContext):
 *
 *   firebase — the same identity the Android app uses. An account created on
 *              the phone signs in here and vice versa; Google works too.
 *   local    — this server's own bcrypt accounts. Not shared with the app,
 *              and the screen says so rather than letting someone discover it
 *              when their phone password is rejected.
 *
 * `authMode` is null until the health check answers. The form waits for it,
 * because rendering the local form first and swapping it would mean showing
 * the wrong password rules to whoever types fast.
 */
export default function Login() {
  const { user, loading, authMode, login, register, loginWithGoogle, resetPassword } =
    useAuth();
  const location = useLocation();

  const [mode, setMode] = useState('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [busy, setBusy] = useState(false);

  if (loading || authMode === null) {
    return (
      <div className="auth-wrap">
        <div className="row">
          <Spinner />
          <span>Loading…</span>
        </div>
      </div>
    );
  }
  if (user) {
    return <Navigate to={location.state?.from?.pathname ?? '/dashboard'} replace />;
  }

  const shared = authMode === 'firebase';
  // Firebase enforces six; the local accounts enforce ten. Showing the wrong
  // number is a small lie that costs a failed submit.
  const minPassword = shared ? 6 : 10;

  const run = async (fn) => {
    setError('');
    setNotice('');
    setBusy(true);
    try {
      await fn();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const submit = (event) => {
    event.preventDefault();
    run(() =>
      mode === 'login' ? login(email, password) : register(email, password, displayName),
    );
  };

  const forgot = () => {
    if (!email) {
      setError('Enter your email address first, then choose Forgot password.');
      return;
    }
    run(async () => {
      await resetPassword(email);
      // Deliberately unconditional: confirming whether an address exists would
      // let anyone enumerate registered accounts.
      setNotice('If that address has an account, a reset link is on its way.');
    });
  };

  return (
    <div className="auth-wrap">
      <div className="auth-card">
        <div className="auth-brand">
          <span className="rail-mark" aria-hidden="true">
            <Icon name="shield" size={16} />
          </span>
          CyberGuard
        </div>
        <p className="hint" style={{ marginBottom: 18 }}>
          Phishing, app, breach and Wi-Fi analysis — the same detection engines
          the Android app runs.
        </p>

        {error && <Banner kind="error">{error}</Banner>}
        {notice && <Banner kind="success">{notice}</Banner>}

        {shared ? (
          <>
            <button
              type="button"
              className="btn google block lg"
              disabled={busy}
              onClick={() => run(loginWithGoogle)}
            >
              Continue with Google
            </button>
            <div className="auth-divider">or</div>
          </>
        ) : (
          <Banner kind="warn">
            These accounts live on this server only — they are not shared with
            the Android app. Set <code className="mono">FIREBASE_PROJECT_ID</code>{' '}
            and the <code className="mono">VITE_FIREBASE_*</code> values to use
            one login for both.
          </Banner>
        )}

        <form onSubmit={submit} style={{ marginTop: shared ? 0 : 16 }}>
          {mode === 'register' && !shared && (
            <label className="field" htmlFor="displayName">
              <span>Name (optional)</span>
              <input
                id="displayName"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                autoComplete="name"
                maxLength={80}
              />
            </label>
          )}

          <label className="field" htmlFor="email">
            <span>Email</span>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              placeholder="you@example.com"
            />
          </label>

          <label className="field" htmlFor="password">
            <span>Password</span>
            <input
              id="password"
              type="password"
              required
              minLength={minPassword}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              // Tells the password manager which flow this is, so it offers to
              // save on register and fill on sign-in.
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
            />
            {mode === 'register' && (
              <div className="hint" style={{ marginTop: 6 }}>
                {shared
                  ? `At least ${minPassword} characters. Held by Firebase — this server never sees it.`
                  : `At least ${minPassword} characters. Stored only as a bcrypt hash.`}
              </div>
            )}
          </label>

          <button type="submit" className="btn block lg" disabled={busy}>
            {busy ? <Spinner /> : mode === 'login' ? 'Sign in' : 'Create account'}
          </button>
        </form>

        <div className="spread" style={{ marginTop: 14 }}>
          <button
            type="button"
            className="link"
            onClick={() => {
              setMode(mode === 'login' ? 'register' : 'login');
              setError('');
              setNotice('');
            }}
          >
            {mode === 'login' ? 'Create an account' : 'I already have an account'}
          </button>
          {shared && mode === 'login' && (
            <button type="button" className="link" onClick={forgot}>
              Forgot password
            </button>
          )}
        </div>

        {shared && (
          <p className="hint" style={{ marginTop: 18 }}>
            <Icon name="shield_outlined" size={12} /> This is the same account as
            the CyberGuard Android app. Sign in with either one.
          </p>
        )}
      </div>
    </div>
  );
}
