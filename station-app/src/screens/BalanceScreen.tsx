import { useQuery } from "@tanstack/react-query";

import { useStationSession } from "@station/contexts/StationSessionContext";
import "@station/styles/balance.css";

export const BalanceScreen = () => {
  const { session, client } = useStationSession();
  const { data, isLoading, isError } = useQuery({
    queryKey: ["station-balance", session?.stationId],
    queryFn: () => client.balance(),
    staleTime: 60_000,
    enabled: Boolean(session?.stationId),
  });

  if (!stationId) {
    return null;
  }

  if (isLoading) {
    return (
      <section className="balance" aria-busy="true">
        <div className="balance__card">
          <p>Loading balance…</p>
        </div>
      </section>
    );
  }

  if (isError || !data) {
    return (
      <section className="balance" aria-live="assertive">
        <div className="balance__card balance__card--error">
          <h1>Balance unavailable</h1>
          <p>Check your connection and try again.</p>
        </div>
      </section>
    );
  }

  return (
    <section className="balance" aria-live="polite">
      <div className="balance__card">
        <h1>Station balance</h1>
        <p className="balance__total">
          {data.available.toLocaleString(undefined, { style: "currency", currency: data.currency })}
        </p>
        <dl className="balance__meta">
          <div>
            <dt>Pending vouchers</dt>
            <dd>{data.pending.toLocaleString(undefined, { style: "currency", currency: data.currency })}</dd>
          </div>
          <div>
            <dt>Last synced</dt>
            <dd>{new Date(data.lastSyncedAt).toLocaleString()}</dd>
          </div>
        </dl>
      </div>
    </section>
  );
};
