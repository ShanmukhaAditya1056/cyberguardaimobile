import { NavLink, Navigate, Route, Routes, useLocation } from 'react-router-dom';

import { useAuth } from './context/AuthContext.jsx';
import { Spinner } from './components/ui.jsx';
import { Icon } from './components/icons.jsx';
import { useDashboard } from './context/DashboardContext.jsx';
import Alerts from './pages/Alerts.jsx';
import Breach from './pages/Breach.jsx';
import Dashboard from './pages/Dashboard.jsx';
import Defense from './pages/Defense.jsx';
import Login from './pages/Login.jsx';
import Malware from './pages/Malware.jsx';
import Phishing from './pages/Phishing.jsx';
import Settings from './pages/Settings.jsx';
import Wifi from './pages/Wifi.jsx';

/**
 * Sign-in gate.
 *
 * Mandatory, matching the app's route guard. The scanners themselves work
 * without an account — every engine runs on the submitted input alone — but
 * history, the unified score and the Evil Twin check all need somewhere to
 * store per-user state, and without an account there is nowhere.
 */
function RequireAuth({ children }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="auth-wrap">
        <div className="row">
          <Spinner />
          <span>Checking your session…</span>
        </div>
      </div>
    );
  }
  // `state` carries where they were headed so sign-in can return them there
  // rather than dumping everyone on the dashboard.
  if (!user) return <Navigate to="/login" replace state={{ from: location }} />;
  return children;
}

/**
 * Navigation.
 *
 * The phone has no persistent nav — its dashboard's module grid is the hub and
 * each module carries a back arrow, which suits a thumb and one screen at a
 * time. A desktop console does not: every destination stays visible, because
 * the whole point of the wider viewport is not having to go back first.
 *
 * Under 900px this same markup becomes a bottom bar (see index.css). Not a
 * hamburger — six destinations *are* the app, and hiding them would put two
 * taps in front of every navigation.
 */
const NAV = [
  { to: '/dashboard', label: 'Overview', icon: 'grid_view' },
  { to: '/phishing', label: 'Phishing', icon: 'link' },
  { to: '/malware', label: 'Apps', icon: 'bug_report' },
  { to: '/wifi', label: 'Wi-Fi', icon: 'wifi' },
  { to: '/breach', label: 'Breaches', icon: 'lock_person' },
  { to: '/defense', label: 'Defence', icon: 'travel_explore' },
];

function Rail() {
  const { unreadAlerts } = useDashboard();

  return (
    <nav className="rail" aria-label="Main">
      <NavLink to="/dashboard" className="rail-brand">
        <span className="rail-mark" aria-hidden="true">
          <Icon name="shield" size={16} />
        </span>
        CyberGuard
      </NavLink>

      <div className="rail-section">Scanners</div>
      {NAV.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          className={({ isActive }) => (isActive ? 'rail-link active' : 'rail-link')}
        >
          <Icon name={item.icon} size={18} />
          {item.label}
        </NavLink>
      ))}

      <div className="rail-section">Account</div>
      <NavLink
        to="/alerts"
        className={({ isActive }) => (isActive ? 'rail-link active' : 'rail-link')}
      >
        <Icon name="notifications_outlined" size={18} />
        Alerts
        {unreadAlerts > 0 && (
          <span className="count" aria-label={`${unreadAlerts} unread`}>
            {unreadAlerts > 99 ? '99+' : unreadAlerts}
          </span>
        )}
      </NavLink>
      <NavLink
        to="/settings"
        className={({ isActive }) => (isActive ? 'rail-link active' : 'rail-link')}
      >
        <Icon name="settings_outlined" size={18} />
        Settings
      </NavLink>
    </nav>
  );
}

/** Shows which account is signed in, and how — local or shared with the app. */
function Topbar() {
  const { user, usesFirebase, logout } = useAuth();
  const name = user?.displayName || user?.email || '';

  return (
    <header className="topbar">
      <span className="topbar-title">Security console</span>
      <span className="topbar-spacer" />
      <span
        className="hint"
        title={
          usesFirebase
            ? 'Signed in through Firebase — the same account as the Android app.'
            : 'A local account on this server. It is not shared with the app.'
        }
      >
        {name}
      </span>
      <button type="button" className="icon-btn" onClick={logout} aria-label="Sign out">
        <Icon name="logout" size={18} />
      </button>
    </header>
  );
}

function Shell({ children }) {
  return (
    <div className="app">
      <Rail />
      <div>
        <Topbar />
        <main className="content">{children}</main>
      </div>
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
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </Shell>
          </RequireAuth>
        }
      />
    </Routes>
  );
}
