import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import { api } from '../lib/api.js';
import {
  describeAuthError,
  firebaseReady,
  firebaseSignOut,
  registerWithEmail as fbRegister,
  sendPasswordReset as fbReset,
  signInWithEmail as fbSignIn,
  signInWithGoogle as fbGoogle,
} from '../lib/firebase.js';

const AuthContext = createContext(null);

/**
 * Two ways in, one session.
 *
 * When Firebase is configured on both this client and the API, sign-in goes
 * through Firebase — the same project the Android app uses, so an account made
 * on the phone works here and vice versa. The ID token is presented to
 * `/auth/session` exactly once and traded for the httpOnly cookie; it is never
 * stored, so nothing readable by page scripts can be replayed.
 *
 * When Firebase is not configured, the API's own email/password accounts are
 * used instead. That path is not a leftover — it is what CI runs on, and what
 * a checkout with no Firebase project falls back to.
 */
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  // Starts true so the router never flashes the login screen before the
  // session has been checked — on a reload the cookie is present but
  // `/auth/me` has not answered yet.
  const [loading, setLoading] = useState(true);
  // Whether the *server* also has Firebase configured. Both halves must agree
  // before the Firebase path is offered: client-only config would produce a
  // token the API cannot verify, and the failure would land after the user had
  // already typed their password.
  const [serverFirebase, setServerFirebase] = useState(null);

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

    api
      .health()
      .then((h) => {
        if (!cancelled) setServerFirebase(Boolean(h.firebaseAuth));
      })
      .catch(() => {
        if (!cancelled) setServerFirebase(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const usesFirebase = firebaseReady && serverFirebase === true;

  /** Turns a Firebase error into the same shape the API layer throws. */
  const viaFirebase = useCallback(async (getToken) => {
    let idToken;
    try {
      idToken = await getToken();
    } catch (err) {
      const message = describeAuthError(err.code);
      // An empty message means the user dismissed the popup — not an error,
      // and it must not surface as one.
      if (!message) return null;
      throw new Error(message);
    }
    const res = await api.auth.session(idToken);
    setUser(res.user);
    return res.user;
  }, []);

  const login = useCallback(
    async (email, password) => {
      if (usesFirebase) return viaFirebase(() => fbSignIn(email, password));
      const res = await api.auth.login({ email, password });
      setUser(res.user);
      return res.user;
    },
    [usesFirebase, viaFirebase],
  );

  const register = useCallback(
    async (email, password, displayName) => {
      if (usesFirebase) return viaFirebase(() => fbRegister(email, password));
      const res = await api.auth.register({ email, password, displayName });
      setUser(res.user);
      return res.user;
    },
    [usesFirebase, viaFirebase],
  );

  const loginWithGoogle = useCallback(async () => {
    if (!usesFirebase) throw new Error('Google sign-in needs Firebase configured.');
    return viaFirebase(fbGoogle);
  }, [usesFirebase, viaFirebase]);

  const resetPassword = useCallback(
    async (email) => {
      if (usesFirebase) await fbReset(email);
      // With local accounts there is no reset flow, and inventing a silent
      // no-op that looks successful would be worse than saying so.
    },
    [usesFirebase],
  );

  const logout = useCallback(async () => {
    try {
      // Both sides, always. Clearing only the cookie would leave Firebase able
      // to mint a fresh token and sign the user back in on the next visit.
      await Promise.allSettled([api.auth.logout(), firebaseSignOut()]);
    } finally {
      // Clear locally even if a request failed — the user asked to sign out,
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
    () => ({
      user,
      loading,
      usesFirebase,
      // null while unknown, so the sign-in screen can wait rather than briefly
      // showing the wrong form.
      authMode: serverFirebase === null ? null : usesFirebase ? 'firebase' : 'local',
      login,
      register,
      loginWithGoogle,
      resetPassword,
      logout,
      updateSettings,
    }),
    [
      user,
      loading,
      usesFirebase,
      serverFirebase,
      login,
      register,
      loginWithGoogle,
      resetPassword,
      logout,
      updateSettings,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
