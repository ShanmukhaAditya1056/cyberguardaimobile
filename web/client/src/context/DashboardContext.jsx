import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import { api } from '../lib/api.js';
import { useAuth } from './AuthContext.jsx';

const DashboardContext = createContext(null);

/**
 * The dashboard summary, shared between the app bar and the dashboard page.
 *
 * The app's bell badge and its dashboard body both read one `DashboardState`
 * from the same Riverpod provider. Fetching `/api/dashboard` twice here would
 * be the same data over two round trips, and — because the two responses land
 * at different moments — could briefly show a badge count that disagrees with
 * the page under it.
 */
export function DashboardProvider({ children }) {
  const { user } = useAuth();
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      setData(await api.dashboard.summary());
      setError('');
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Signing out must drop the previous account's counts immediately rather
    // than leaving them on screen until the next sign-in resolves.
    if (!user) {
      setData(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    refresh();
  }, [user, refresh]);

  const value = useMemo(
    () => ({
      data,
      error,
      loading,
      refresh,
      unreadAlerts: data?.unreadAlerts ?? 0,
    }),
    [data, error, loading, refresh],
  );

  return <DashboardContext.Provider value={value}>{children}</DashboardContext.Provider>;
}

export function useDashboard() {
  const ctx = useContext(DashboardContext);
  if (!ctx) throw new Error('useDashboard must be used inside <DashboardProvider>');
  return ctx;
}
