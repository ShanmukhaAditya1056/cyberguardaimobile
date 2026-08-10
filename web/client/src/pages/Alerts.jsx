import { useCallback, useEffect, useState } from 'react';

import { api } from '../lib/api.js';
import {
  Banner,
  EmptyState,
  RiskBadge,
  Spinner,
  formatDate,
} from '../components/ui.jsx';

const MODULES = ['phishing', 'malware', 'breach', 'wifi'];

export default function Alerts() {
  const [alerts, setAlerts] = useState(null);
  const [module, setModule] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [error, setError] = useState('');

  const load = useCallback(() => {
    const params = {};
    if (module) params.module = module;
    if (unreadOnly) params.unreadOnly = 'true';
    api.dashboard
      .alerts(params)
      .then((r) => setAlerts(r.alerts))
      .catch((e) => setError(e.message));
  }, [module, unreadOnly]);

  useEffect(load, [load]);

  const markRead = async (id) => {
    await api.dashboard.markRead(id);
    load();
  };

  const remove = async (id) => {
    await api.dashboard.removeAlert(id);
    load();
  };

  const markAll = async () => {
    await api.dashboard.markAllRead();
    load();
  };

  return (
    <>
      <div className="spread">
        <h1 style={{ margin: 0 }}>Alerts</h1>
        <button type="button" className="secondary" onClick={markAll}>
          Mark all read
        </button>
      </div>

      <Banner kind="error">{error}</Banner>

      <div className="chips" style={{ margin: '16px 0' }}>
        <button
          type="button"
          className={`chip ${module === '' ? 'on' : ''}`}
          onClick={() => setModule('')}
        >
          All
        </button>
        {MODULES.map((m) => (
          <button
            key={m}
            type="button"
            className={`chip ${module === m ? 'on' : ''}`}
            onClick={() => setModule(m)}
          >
            {m}
          </button>
        ))}
        <button
          type="button"
          className={`chip ${unreadOnly ? 'on' : ''}`}
          aria-pressed={unreadOnly}
          onClick={() => setUnreadOnly((v) => !v)}
        >
          Unread only
        </button>
      </div>

      <div className="card">
        {alerts === null ? (
          <Spinner />
        ) : alerts.length === 0 ? (
          <EmptyState
            title="Nothing to report"
            hint="Alerts appear here when a scan finds something."
          />
        ) : (
          <ul className="list">
            {alerts.map((alert) => (
              <li key={alert._id}>
                <div style={{ minWidth: 0 }}>
                  <div className="row" style={{ gap: 8 }}>
                    <RiskBadge level={alert.type} />
                    <strong
                      style={{ fontWeight: alert.isRead ? 500 : 800 }}
                    >
                      {alert.title}
                    </strong>
                  </div>
                  <div style={{ marginTop: 4 }}>{alert.description}</div>
                  <div className="muted" style={{ marginTop: 4 }}>
                    {alert.module} · {formatDate(alert.createdAt)}
                  </div>
                </div>
                <div className="row">
                  {!alert.isRead && (
                    <button
                      type="button"
                      className="link"
                      onClick={() => markRead(alert._id)}
                    >
                      Mark read
                    </button>
                  )}
                  <button
                    type="button"
                    className="link"
                    onClick={() => remove(alert._id)}
                  >
                    Delete
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
