"use client";

import { useState, useEffect } from "react";
import { Drawer } from "@/components/ui/Drawer";
import { Button } from "@/components/ui/Button";
import { useAgentSessionDetail, useUpdateAgentSession } from "@/lib/queries/agent-orchestration";
import type { AgentSession, AgentQuote } from "@/lib/queries/agent-orchestration";

interface SessionDrawerProps {
  sessionId: string;
  onClose: () => void;
}

function SlaCountdown({ deadline }: { deadline: string }) {
  const [remaining, setRemaining] = useState<number>(0);

  useEffect(() => {
    const updateRemaining = () => {
      const ms = new Date(deadline).getTime() - Date.now();
      setRemaining(Math.max(0, ms));
    };

    updateRemaining();
    const interval = setInterval(updateRemaining, 1000);
    return () => clearInterval(interval);
  }, [deadline]);

  const seconds = Math.floor(remaining / 1000);
  const minutes = Math.floor(seconds / 60);
  const isUrgent = seconds < 60;

  return (
    <span className={`font-mono font-medium ${isUrgent ? "text-red-600 font-bold" : "text-gray-600"}`}>
      {minutes}:{(seconds % 60).toString().padStart(2, "0")}
    </span>
  );
}

export function SessionDrawer({ sessionId, onClose }: SessionDrawerProps) {
  const { data, isLoading, error, refetch } = useAgentSessionDetail(sessionId);
  const updateSession = useUpdateAgentSession(sessionId);

  useEffect(() => {
    // Auto-refresh every 5 seconds for live updates
    const interval = setInterval(() => {
      refetch();
    }, 5000);
    return () => clearInterval(interval);
  }, [refetch]);

  const handleExtendDeadline = async () => {
    if (!data?.session) return;
    try {
      await updateSession.mutateAsync({ extend_deadline: true });
      refetch();
    } catch (error) {
      console.error("Failed to extend deadline:", error);
    }
  };

  const handleCancel = async () => {
    if (!data?.session) return;
    if (!confirm("Are you sure you want to cancel this session?")) return;

    try {
      await updateSession.mutateAsync({
        status: "cancelled",
        cancellation_reason: "Admin cancelled",
      });
      refetch();
    } catch (error) {
      console.error("Failed to cancel session:", error);
    }
  };

  const handleSelectQuote = async (quoteId: string) => {
    if (!data?.session) return;
    if (!confirm("Are you sure you want to select this quote?")) return;

    try {
      await updateSession.mutateAsync({
        status: "completed",
        selected_quote_id: quoteId,
      });
      refetch();
    } catch (error) {
      console.error("Failed to select quote:", error);
    }
  };

  if (isLoading) {
    return (
      <Drawer title="Loading..." onClose={onClose}>
        <div className="text-center py-8 text-gray-600">Loading session details...</div>
      </Drawer>
    );
  }

  if (error || !data?.session) {
    return (
      <Drawer title="Error" onClose={onClose}>
        <div className="text-center py-8 text-red-600">Failed to load session details</div>
      </Drawer>
    );
  }

  const session: AgentSession = data.session;
  const quotes: AgentQuote[] = data.quotes || [];
  const maxExtensions = session.max_extensions ?? 2;

  return (
    <Drawer title={`Session ${session.id.slice(0, 8)}...`} onClose={onClose}>
      {/* Session Header */}
      <div className="space-y-4 pb-6 border-b">
        <div className="flex items-center gap-3">
          <span
            className={`inline-flex items-center rounded-full px-3 py-1 text-sm font-medium ${
              session.status === "searching"
                ? "bg-blue-100 text-blue-700"
                : session.status === "negotiating"
                ? "bg-yellow-100 text-yellow-700"
                : session.status === "completed"
                ? "bg-green-100 text-green-700"
                : session.status === "timeout"
                ? "bg-red-100 text-red-700"
                : "bg-gray-100 text-gray-700"
            }`}
          >
            {session.status}
          </span>
          {(session.status === "searching" || session.status === "negotiating") && (
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">Deadline:</span>
              <SlaCountdown deadline={session.deadline_at} />
            </div>
          )}
        </div>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-gray-600">Flow Type</div>
            <div className="font-medium">{session.flow_type}</div>
          </div>
          <div>
            <div className="text-gray-600">Agent Type</div>
            <div className="font-medium">{session.agent_type}</div>
          </div>
          <div>
            <div className="text-gray-600">Started</div>
            <div className="font-medium">{new Date(session.started_at).toLocaleString()}</div>
          </div>
          <div>
            <div className="text-gray-600">Extensions</div>
            <div className="font-medium">
              {session.extensions_count}/{maxExtensions}
            </div>
          </div>
        </div>
      </div>

      {/* Request Details */}
      <div className="py-6 border-b">
        <h3 className="text-lg font-semibold mb-3">Request Details</h3>
        <pre className="bg-gray-50 p-4 rounded text-xs overflow-auto max-h-64">
          {JSON.stringify(session.request_data, null, 2)}
        </pre>
      </div>

      {/* Quotes */}
      <div className="py-6 border-b">
        <h3 className="text-lg font-semibold mb-3">Quotes ({quotes.length})</h3>
        {quotes.length === 0 && (
          <div className="text-center py-8 text-gray-600">No quotes received yet</div>
        )}
        {quotes.length > 0 && (
          <div className="space-y-3">
            {quotes.map((quote) => (
              <div
                key={quote.id}
                className={`border rounded p-4 ${
                  quote.id === session.selected_quote_id ? "border-green-500 bg-green-50" : ""
                }`}
              >
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <div className="font-medium">{quote.vendor_name || "Unknown Vendor"}</div>
                    <div className="text-xs text-gray-600">{quote.vendor_type}</div>
                  </div>
                  <span
                    className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                      quote.status === "accepted"
                        ? "bg-green-100 text-green-700"
                        : quote.status === "rejected"
                        ? "bg-red-100 text-red-700"
                        : "bg-gray-100 text-gray-700"
                    }`}
                  >
                    {quote.status}
                  </span>
                </div>
                <div className="text-sm mb-2">
                  <pre className="bg-white p-2 rounded text-xs overflow-auto">
                    {JSON.stringify(quote.offer_data, null, 2)}
                  </pre>
                </div>
                <div className="flex items-center justify-between text-xs text-gray-600">
                  <span>Received: {new Date(quote.responded_at).toLocaleString()}</span>
                  {quote.ranking_score && <span>Score: {quote.ranking_score}</span>}
                </div>
                {session.status === "searching" &&
                  quote.status === "pending" &&
                  !session.selected_quote_id && (
                    <div className="mt-2">
                      <Button
                        size="sm"
                        onClick={() => handleSelectQuote(quote.id)}
                        disabled={updateSession.isPending}
                      >
                        Select This Quote
                      </Button>
                    </div>
                  )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Actions */}
      {(session.status === "searching" || session.status === "negotiating") && (
        <div className="py-6">
          <h3 className="text-lg font-semibold mb-3">Actions</h3>
          <div className="flex gap-3">
            <Button
              onClick={handleExtendDeadline}
              disabled={session.extensions_count >= maxExtensions || updateSession.isPending}
              variant="outline"
            >
              Extend +2 min ({session.extensions_count}/{maxExtensions})
            </Button>
            <Button
              onClick={handleCancel}
              disabled={updateSession.isPending}
              variant="danger"
            >
              Cancel Session
            </Button>
          </div>
        </div>
      )}
    </Drawer>
  );
}
