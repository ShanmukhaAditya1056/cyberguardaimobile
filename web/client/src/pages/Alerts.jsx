import { useCallback, useEffect, useState } from 'react';

import { api } from '../lib/api.js';
import { Icon } from '../components/icons.jsx';
import {
  Banner,
  EmptyState,
  PageHeader,
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
      <PageHeader
        title="Alerts"
        actions={
          <button type="button" className="secondary" onClick={markAll}>
            Mark all read
          </button>
        }
      />

      <div className="pad">
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
              <li
                key={alert._id}
                className="scan-row"
                style={{ alignItems: 'flex-start' }}
              >
                {/* Unread is carried by an accent bar rather than by weight
                    alone — bold-vs-semibold is not a difference you can see
                    when scanning a column of twenty. */}
                <span
                  className="scan-icon"
                  style={{
                    background: alert.isRead ? 'var(--surface-2)' : 'var(--accent-wash)',
                    color: alert.isRead ? 'var(--ink-3)' : 'var(--accent)',
                  }}
                  aria-hidden="true"
                >
                  <Icon name="notifications_outlined" size={15} />
                </span>
                <div className="scan-body">
                  <div className="row" style={{ gap: 8, marginBottom: 3 }}>
                    <RiskBadge level={alert.type} />
                    <strong style={{ fontWeight: alert.isRead ? 500 : 700 }}>
                      {alert.title}
                    </strong>
                    {!alert.isRead && <span className="visually-hidden">(unread)</span>}
                  </div>
                  <div className="muted">{alert.description}</div>
                  <div className="hint" style={{ marginTop: 3 }}>
                    {alert.module} · {formatDate(alert.createdAt)}
                  </div>
                </div>
                <div className="row" style={{ flex: 'none' }}>
                  {!alert.isRead && (
                    <button
                      type="button"
                      className="icon-btn"
                      title="Mark read"
                      aria-label={`Mark "${alert.title}" as read`}
                      onClick={() => markRead(alert._id)}
                    >
                      <Icon name="check_circle" size={16} />
                    </button>
                  )}
                  <button
                    type="button"
                    className="icon-btn"
                    title="Delete"
                    aria-label={`Delete the alert "${alert.title}"`}
                    onClick={() => remove(alert._id)}
                  >
                    <Icon name="delete_outline" size={16} />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
      </div>
    </>
  );
}
