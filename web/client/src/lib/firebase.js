/**
 * Firebase sign-in for the browser — the same project the Android app
 * authenticates against, which is what makes one account work on both.
 *
 * Configuration is optional, exactly as it is in the app: a checkout with no
 * `google-services.json` still builds and runs there, and a checkout with no
 * `VITE_FIREBASE_*` still builds and runs here. [firebaseReady] is false, the
 * sign-in screen falls back to this API's own email/password accounts, and
 * nothing throws.
 *
 * These values are not secrets. They ship in every web bundle by design, and
 * Firebase security rests on the project's auth settings and authorised
 * domains, not on hiding them. They stay out of git only because they identify
 * one specific project — the same reasoning that keeps google-services.json
 * untracked.
 *
 * To fill them in: Firebase console → the project the app uses → Add app →
 * Web, then copy the config into `web/client/.env.local`.
 */

const cfg = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  // Only needed if this client ever talks to Storage or FCM. Harmless when
  // absent, so it is not part of the readiness test below.
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
};

/** Whether sign-in through Firebase is possible in this build. */
export const firebaseReady = Boolean(
  cfg.apiKey && cfg.authDomain && cfg.projectId && cfg.appId,
);

export const firebaseProjectId = cfg.projectId ?? '';

let authPromise = null;

/**
 * Loads the SDK on first use and returns its `auth` instance.
 *
 * Imported dynamically so the ~200 KB of Firebase never enters the initial
 * bundle for a visitor who is only scanning a URL — every scanner works signed
 * out, so most sessions never reach a sign-in at all.
 */
async function getAuthInstance() {
  if (!firebaseReady) throw new Error('Firebase is not configured');
  if (!authPromise) {
    authPromise = (async () => {
      const { initializeApp, getApps, getApp } = await import('firebase/app');
      const { getAuth } = await import('firebase/auth');
      const app = getApps().length ? getApp() : initializeApp(cfg);
      return getAuth(app);
    })();
  }
  return authPromise;
}

/**
 * Firebase's error codes, in words a person can act on.
 *
 * `invalid-credential` deliberately covers both a wrong password and an
 * unknown address: Firebase merged them precisely so a sign-in form cannot be
 * used to enumerate which addresses are registered, and re-separating them
 * here would undo that.
 */
export function describeAuthError(code) {
  switch (code) {
    case 'auth/invalid-email':
      return 'That does not look like an email address.';
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'Email or password is incorrect.';
    case 'auth/email-already-in-use':
      return 'That address already has an account. Try signing in.';
    case 'auth/weak-password':
      return 'Use a longer password — at least six characters.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again.';
    case 'auth/network-request-failed':
      return 'Cannot reach Firebase. Check your connection.';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return '';
    case 'auth/unauthorized-domain':
      return 'This domain is not authorised in the Firebase console.';
    case 'auth/operation-not-allowed':
      return 'That sign-in method is disabled in the Firebase console.';
    default:
      return 'Sign-in failed. Please try again.';
  }
}

export async function signInWithEmail(email, password) {
  const auth = await getAuthInstance();
  const { signInWithEmailAndPassword } = await import('firebase/auth');
  const cred = await signInWithEmailAndPassword(auth, email.trim(), password);
  return cred.user.getIdToken();
}

export async function registerWithEmail(email, password) {
  const auth = await getAuthInstance();
  const { createUserWithEmailAndPassword } = await import('firebase/auth');
  const cred = await createUserWithEmailAndPassword(auth, email.trim(), password);
  return cred.user.getIdToken();
}

export async function signInWithGoogle() {
  const auth = await getAuthInstance();
  const { GoogleAuthProvider, signInWithPopup } = await import('firebase/auth');
  const cred = await signInWithPopup(auth, new GoogleAuthProvider());
  return cred.user.getIdToken();
}

export async function sendPasswordReset(email) {
  const auth = await getAuthInstance();
  const { sendPasswordResetEmail } = await import('firebase/auth');
  // Errors are swallowed for the same reason the app swallows them: reporting
  // whether an address exists would let anyone enumerate registered accounts.
  try {
    await sendPasswordResetEmail(auth, email.trim());
  } catch {
    /* intentionally silent */
  }
}

/**
 * Ends the Firebase session.
 *
 * The API cookie is cleared separately by `/auth/logout`. Both must happen:
 * clearing only the cookie would leave Firebase able to mint a fresh token and
 * silently sign the user back in on the next visit.
 */
export async function firebaseSignOut() {
  if (!firebaseReady) return;
  try {
    const auth = await getAuthInstance();
    const { signOut } = await import('firebase/auth');
    await signOut(auth);
  } catch {
    /* already signed out, or the SDK never loaded */
  }
}
