import { useState } from 'react';
import { Navigate, useLocation } from 'react-router-dom';

import { useAuth } from '../context/AuthContext.jsx';
import { Banner, Spinner } from '../components/ui.jsx';

export default function Login() {
  const { user, loading, login, register } = useAuth();
  const location = useLocation();

  const [mode, setMode] = useState('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  if (loading) {
    return (
      <div className="auth-wrap">
        <Spinner />
      </div>
    );
  }
  if (user) {
    return <Navigate to={location.state?.from?.pathname ?? '/dashboard'} replace />;
  }

  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      if (mode === 'login') {
        await login(email, password);
      } else {
        await register(email, password, displayName);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="auth-wrap">
      <div className="card auth-card">
        <h1>
          Cyber<span style={{ color: 'var(--blue)' }}>Guard</span> AI
        </h1>
        <p className="muted" style={{ marginBottom: 22 }}>
          Phishing, malware, breach and Wi-Fi checks — running the same
          detection engines as the mobile app.
        </p>

        <Banner kind="error">{error}</Banner>

        <form onSubmit={submit}>
          {mode === 'register' && (
            <div className="field">
              <label htmlFor="displayName">Name (optional)</label>
              <input
                id="displayName"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                autoComplete="name"
                maxLength={80}
              />
            </div>
          )}

          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
            />
          </div>

          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              required
              minLength={10}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              // Tells the password manager which flow this is, so it offers to
              // save a new password on register and fill on sign-in.
              autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
            />
            {mode === 'register' && (
              <div className="hint">
                At least 10 characters. Stored only as a bcrypt hash.
              </div>
            )}
          </div>

          <button type="submit" disabled={busy} style={{ width: '100%' }}>
            {busy ? <Spinner /> : mode === 'login' ? 'Sign in' : 'Create account'}
          </button>
        </form>

        <div style={{ marginTop: 16, textAlign: 'center' }}>
          <button
            type="button"
            className="link"
            onClick={() => {
              setMode(mode === 'login' ? 'register' : 'login');
              setError('');
            }}
          >
            {mode === 'login'
              ? 'No account? Create one'
              : 'Already registered? Sign in'}
          </button>
        </div>
      </div>
    </div>
  );
}
