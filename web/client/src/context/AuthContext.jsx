import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

import { api } from '../lib/api.js';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  // Starts true so the router never flashes the login screen before the
  // session has been checked — on a reload the cookie is present but
  // `/auth/me` has not answered yet.
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    api.auth
      .me()
      .then((res) => {
        if (!cancelled) setUser(res.user);
      })
      // A 401 here is the normal signed-out case, not an error worth showing.
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const login = useCallback(async (email, password) => {
    const res = await api.auth.login({ email, password });
    setUser(res.user);
    return res.user;
  }, []);

  const register = useCallback(async (email, password, displayName) => {
    const res = await api.auth.register({ email, password, displayName });
    setUser(res.user);
    return res.user;
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.auth.logout();
    } finally {
      // Clear locally even if the request failed — the user asked to sign out,
      // and leaving them looking signed in is the worse outcome.
      setUser(null);
    }
  }, []);

  const updateSettings = useCallback(async (settings) => {
    const res = await api.auth.updateSettings(settings);
    setUser(res.user);
    return res.user;
  }, []);

  const value = useMemo(
    () => ({ user, loading, login, register, logout, updateSettings }),
    [user, loading, login, register, logout, updateSettings],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
