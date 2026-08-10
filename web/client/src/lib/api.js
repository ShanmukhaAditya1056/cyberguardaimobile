/**
 * Thin fetch wrapper.
 *
 * `credentials: 'include'` on every call is what carries the httpOnly session
 * cookie — the token is deliberately not readable from JavaScript, so there is
 * no Authorization header to set here (see `server/src/middleware/auth.js`).
 */

const BASE = '/api';

export class ApiError extends Error {
  constructor(message, status, details) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.details = details;
  }
}

async function request(path, { method = 'GET', body, signal } = {}) {
  let response;
  try {
    response = await fetch(`${BASE}${path}`, {
      method,
      credentials: 'include',
      headers: body ? { 'Content-Type': 'application/json' } : undefined,
      body: body ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (err) {
    if (err.name === 'AbortError') throw err;
    // fetch only rejects on a transport failure, so this is genuinely "the
    // API is unreachable" rather than any HTTP error — worth saying plainly
    // instead of surfacing "Failed to fetch".
    throw new ApiError('Cannot reach the CyberGuard API. Is the server running?', 0);
  }

  if (response.status === 204) return null;

  let payload = null;
  try {
    payload = await response.json();
  } catch {
    payload = null;
  }

  if (!response.ok) {
    throw new ApiError(
      payload?.error ?? `Request failed (${response.status})`,
      response.status,
      payload?.details,
    );
  }
  return payload;
}

export const api = {
  health: () => request('/health'),

  auth: {
    register: (body) => request('/auth/register', { method: 'POST', body }),
    login: (body) => request('/auth/login', { method: 'POST', body }),
    logout: () => request('/auth/logout', { method: 'POST' }),
    me: () => request('/auth/me'),
    updateSettings: (body) => request('/auth/settings', { method: 'PATCH', body }),
  },

  phishing: {
    scan: (url) => request('/phishing/scan', { method: 'POST', body: { url } }),
    scanText: (text) =>
      request('/phishing/scan-text', { method: 'POST', body: { text } }),
    history: () => request('/phishing/history'),
    remove: (id) => request(`/phishing/history/${id}`, { method: 'DELETE' }),
  },

  malware: {
    scan: (app) => request('/malware/scan', { method: 'POST', body: app }),
    scanBatch: (apps) =>
      request('/malware/scan-batch', { method: 'POST', body: { apps } }),
    permissions: () => request('/malware/permissions'),
    history: () => request('/malware/history'),
  },

  breach: {
    password: (prefix, suffix) =>
      request('/breach/password', { method: 'POST', body: { prefix, suffix } }),
    account: (email) =>
      request('/breach/account', { method: 'POST', body: { email } }),
    history: () => request('/breach/history'),
  },

  wifi: {
    analyze: (network) =>
      request('/wifi/analyze', { method: 'POST', body: network }),
    history: () => request('/wifi/history'),
    knownNetworks: () => request('/wifi/known-networks'),
    forget: (id) => request(`/wifi/known-networks/${id}`, { method: 'DELETE' }),
  },

  defense: {
    fusionScan: (url, cloudIntel = false) =>
      request('/defense/scan', { method: 'POST', body: { url, cloudIntel } }),
    arbitration: (conflictsOnly = false) =>
      request(`/defense/arbitration${conflictsOnly ? '?conflictsOnly=true' : ''}`),
    removeArbitration: (id) =>
      request(`/defense/arbitration/${id}`, { method: 'DELETE' }),
    risk: () => request('/defense/risk'),
    classifyText: (text) =>
      request('/defense/screenshot', { method: 'POST', body: { text } }),
  },

  dashboard: {
    summary: () => request('/dashboard'),
    alerts: (params = {}) => {
      const qs = new URLSearchParams(params).toString();
      return request(`/dashboard/alerts${qs ? `?${qs}` : ''}`);
    },
    markRead: (id) => request(`/dashboard/alerts/${id}/read`, { method: 'PATCH' }),
    markAllRead: () => request('/dashboard/alerts/read-all', { method: 'POST' }),
    removeAlert: (id) => request(`/dashboard/alerts/${id}`, { method: 'DELETE' }),
    clearHistory: () => request('/dashboard/history', { method: 'DELETE' }),
  },
};
