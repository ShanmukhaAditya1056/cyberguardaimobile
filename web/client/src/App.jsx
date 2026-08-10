import { Navigate, NavLink, Route, Routes, useLocation } from 'react-router-dom';

import { useAuth } from './context/AuthContext.jsx';
import { Spinner } from './components/ui.jsx';
import Alerts from './pages/Alerts.jsx';
import Breach from './pages/Breach.jsx';
import Dashboard from './pages/Dashboard.jsx';
import Defense from './pages/Defense.jsx';
import Login from './pages/Login.jsx';
import Malware from './pages/Malware.jsx';
import Phishing from './pages/Phishing.jsx';
import Settings from './pages/Settings.jsx';
import Wifi from './pages/Wifi.jsx';

const NAV = [
  { to: '/dashboard', label: 'Dashboard' },
  { to: '/phishing', label: 'Phishing' },
  { to: '/malware', label: 'App Scanner' },
  { to: '/breach', label: 'Breach' },
  { to: '/wifi', label: 'Wi-Fi' },
  { to: '/defense', label: 'Defence' },
  { to: '/alerts', label: 'Alerts' },
  { to: '/settings', label: 'Settings' },
];

/**
 * Sign-in gate.
 *
 * Mandatory, matching the mobile app's route guard. The scanners themselves
 * work without an account — every engine runs on the submitted input alone —
 * but history, the unified score and the Evil Twin check all need somewhere to
 * store per-user state, and without an account there is nowhere.
 */
function RequireAuth({ children }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="auth-wrap">
        <Spinner /> <span style={{ marginLeft: 10 }}>Checking your session…</span>
      </div>
    );
  }
  // `state` carries where they were headed so sign-in can return them there
  // rather than dumping everyone on the dashboard.
  if (!user) return <Navigate to="/login" replace state={{ from: location }} />;
  return children;
}

function Shell({ children }) {
  const { user, logout } = useAuth();

  return (
    <div className="app">
      <header className="topbar">
        <NavLink to="/dashboard" className="brand">
          Cyber<span>Guard</span> AI
        </NavLink>
        <nav className="nav">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) => (isActive ? 'active' : undefined)}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="row">
          <span className="muted">{user?.email}</span>
          <button className="secondary" type="button" onClick={logout}>
            Sign out
          </button>
        </div>
      </header>
      <main className="content">{children}</main>
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/*"
        element={
          <RequireAuth>
            <Shell>
              <Routes>
                <Route path="/" element={<Navigate to="/dashboard" replace />} />
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/phishing" element={<Phishing />} />
                <Route path="/malware" element={<Malware />} />
                <Route path="/breach" element={<Breach />} />
                <Route path="/wifi" element={<Wifi />} />
                <Route path="/defense" element={<Defense />} />
                <Route path="/alerts" element={<Alerts />} />
                <Route path="/settings" element={<Settings />} />
                <Route
                  path="*"
                  element={<Navigate to="/dashboard" replace />}
                />
              </Routes>
            </Shell>
          </RequireAuth>
        }
      />
    </Routes>
  );
}
