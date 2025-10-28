import { useQuery } from "@tanstack/react-query";

import { useStationSession } from "@station/contexts/StationSessionContext";
import { maskMsisdn } from "@station/utils/msisdn";
import "@station/styles/history.css";

export const HistoryScreen = () => {
  const { session, client } = useStationSession();
  const { data, isLoading, isError } = useQuery({
    queryKey: ["station-history", session?.stationId],
    queryFn: () => client.history(),
    staleTime: 30_000,
    enabled: Boolean(session?.stationId),
  });

  if (!stationId) {
    return null;
  }

  if (isLoading) {
    return (
      <section className="history" aria-busy="true">
        <p>Loading redemption history…</p>
      </section>
    );
  }

  if (isError || !data) {
    return (
      <section className="history" aria-live="assertive">
        <p role="alert">History unavailable right now. Try again shortly.</p>
      </section>
    );
  }

  if (data.items.length === 0) {
    return (
      <section className="history" aria-live="polite">
        <div className="history__empty">
          <p>No redemptions yet today. Redeem to see them listed here.</p>
        </div>
      </section>
    );
  }

  return (
    <section className="history" aria-live="polite">
      <h1>Recent redemptions</h1>
      <ul className="history__list">
        {data.items.map((item) => {
          const masked = item.maskedMsisdn ? (item.maskedMsisdn.includes("*") ? item.maskedMsisdn : maskMsisdn(item.maskedMsisdn)) : "";
          return (
            <li key={item.reference} className="history__item">
              <div>
                <p className="history__amount">
                  {item.amount.toLocaleString(undefined, { style: "currency", currency: item.currency })}
                </p>
                <p className="history__msisdn" aria-label="Masked MSISDN">
                  {masked}
                </p>
              </div>
              <div className="history__meta">
                <span>{new Date(item.redeemedAt).toLocaleTimeString()}</span>
                <span className={`history__status history__status--${item.status}`}>
                  {item.status === "redeemed" ? "Redeemed" : item.status === "already_redeemed" ? "Already redeemed" : "Declined"}
                </span>
                <span className="history__reference">{item.reference}</span>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
};
