import { Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom';

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
        <Spinner dark /> <span style={{ marginLeft: 10 }}>Checking your session…</span>
      </div>
    );
  }
  // `state` carries where they were headed so sign-in can return them there
  // rather than dumping everyone on the dashboard.
  if (!user) return <Navigate to="/login" replace state={{ from: location }} />;
  return children;
}

/**
 * The dashboard's `SliverAppBar`: brand on the left, alerts bell with its
 * unread count and the settings gear on the right.
 *
 * The app has no persistent nav bar — `CyberGuardBottomNav` exists in
 * `lib/shared/widgets/` but nothing mounts it, and it is still painted in the
 * retired dark-glass style. Copying it would have made the web build look
 * *less* like the shipped app, not more. Navigation is the same as on the
 * phone: the dashboard's module grid is the hub, and every module screen
 * carries a back arrow.
 */
function AppBar() {
  const { unreadAlerts } = useDashboard();
  const navigate = useNavigate();

  return (
    <header className="appbar">
      <a
        className="brand"
        href="/dashboard"
        onClick={(e) => {
          e.preventDefault();
          navigate('/dashboard');
        }}
      >
        CyberGuard AI
      </a>
      <span className="appbar-spacer" />
      <button
        type="button"
        className="icon-btn"
        aria-label={unreadAlerts > 0 ? `Alerts, ${unreadAlerts} unread` : 'Alerts'}
        onClick={() => navigate('/alerts')}
      >
        <Icon name="notifications_outlined" size={24} />
        {unreadAlerts > 0 && (
          <span className="badge-dot" aria-hidden="true">
            {unreadAlerts > 9 ? '9+' : unreadAlerts}
          </span>
        )}
      </button>
      <button
        type="button"
        className="icon-btn"
        aria-label="Settings"
        onClick={() => navigate('/settings')}
      >
        <Icon name="settings_outlined" size={24} />
      </button>
    </header>
  );
}

function Shell({ children }) {
  return (
    <div className="app">
      <AppBar />
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
                <Route path="*" element={<Navigate to="/dashboard" replace />} />
              </Routes>
            </Shell>
          </RequireAuth>
        }
      />
    </Routes>
  );
}
