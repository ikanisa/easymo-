import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

const API_BASE = "/api/agent-orchestration";

// Fetch helper
async function fetchAPI(endpoint: string, options?: RequestInit) {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: "fetch_failed" }));
    throw new Error(error.error || "Request failed");
  }

  return response.json();
}

// ============================================================================
// Agent Sessions
// ============================================================================

export interface AgentSession {
  id: string;
  user_id?: string;
  agent_type: string;
  flow_type: string;
  status: "searching" | "negotiating" | "completed" | "timeout" | "cancelled";
  request_data: Record<string, unknown>;
  started_at: string;
  deadline_at: string;
  completed_at?: string;
  extensions_count: number;
  max_extensions?: number;
  selected_quote_id?: string;
  cancellation_reason?: string;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface AgentQuote {
  id: string;
  session_id: string;
  vendor_id?: string;
  vendor_type: string;
  vendor_name?: string;
  offer_data: Record<string, unknown>;
  status: "pending" | "accepted" | "rejected" | "counter_offered";
  responded_at: string;
  expires_at?: string;
  ranking_score?: number;
  counter_offer_data?: Record<string, unknown>;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SessionsQueryParams {
  status?: string;
  flow_type?: string;
  agent_type?: string;
  limit?: number;
  offset?: number;
}

export function useAgentSessions(params?: SessionsQueryParams) {
  return useQuery({
    queryKey: ["agent-orchestration", "sessions", params],
    queryFn: async ({ signal }) => {
      const query = new URLSearchParams();
      if (params?.status) query.set("status", params.status);
      if (params?.flow_type) query.set("flow_type", params.flow_type);
      if (params?.agent_type) query.set("agent_type", params.agent_type);
      if (params?.limit) query.set("limit", String(params.limit));
      if (params?.offset) query.set("offset", String(params.offset));

      return fetchAPI(`/sessions?${query.toString()}`, { signal });
    },
  });
}

export function useAgentSessionDetail(id?: string) {
  return useQuery({
    queryKey: ["agent-orchestration", "sessions", id],
    queryFn: ({ signal }) => fetchAPI(`/sessions/${id}`, { signal }),
    enabled: Boolean(id),
  });
}

export function useCreateAgentSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: {
      user_id?: string;
      agent_type: string;
      flow_type: string;
      request_data: Record<string, unknown>;
      sla_minutes?: number;
    }) =>
      fetchAPI("/sessions", {
        method: "POST",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "sessions"] });
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "metrics"] });
    },
  });
}

export function useUpdateAgentSession(id: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: {
      status?: string;
      selected_quote_id?: string;
      cancellation_reason?: string;
      extend_deadline?: boolean;
    }) =>
      fetchAPI(`/sessions/${id}`, {
        method: "PATCH",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "sessions", id] });
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "sessions"] });
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "metrics"] });
    },
  });
}

// ============================================================================
// Agent Registry
// ============================================================================

export interface AgentRegistryEntry {
  id: string;
  agent_type: string;
  name: string;
  description?: string;
  enabled: boolean;
  sla_minutes: number;
  max_extensions: number;
  fan_out_limit: number;
  counter_offer_delta_pct: number;
  auto_negotiation: boolean;
  feature_flag_scope: string;
  system_prompt?: string;
  enabled_tools: string[];
  created_at: string;
  updated_at: string;
}

export function useAgentRegistry() {
  return useQuery({
    queryKey: ["agent-orchestration", "registry"],
    queryFn: ({ signal }) => fetchAPI("/registry", { signal }),
  });
}

export function useAgentConfig(agentType?: string) {
  return useQuery({
    queryKey: ["agent-orchestration", "registry", agentType],
    queryFn: ({ signal }) => fetchAPI(`/registry/${agentType}`, { signal }),
    enabled: Boolean(agentType),
  });
}

export function useUpdateAgentConfig(agentType: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: {
      enabled?: boolean;
      sla_minutes?: number;
      max_extensions?: number;
      fan_out_limit?: number;
      counter_offer_delta_pct?: number;
      auto_negotiation?: boolean;
      feature_flag_scope?: string;
      system_prompt?: string;
      enabled_tools?: string[];
    }) =>
      fetchAPI(`/registry/${agentType}`, {
        method: "PATCH",
        body: JSON.stringify(data),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "registry", agentType] });
      qc.invalidateQueries({ queryKey: ["agent-orchestration", "registry"] });
    },
  });
}

// ============================================================================
// Agent Metrics
// ============================================================================

export interface AgentMetrics {
  metrics: Array<{
    id: string;
    agent_type: string;
    metric_date: string;
    total_sessions: number;
    completed_sessions: number;
    timeout_sessions: number;
    cancelled_sessions: number;
    avg_time_to_3_quotes_seconds?: number;
    avg_quotes_per_session?: number;
    acceptance_rate_pct?: number;
    avg_response_time_seconds?: number;
  }>;
  kpis: {
    timeout_rate: string;
    acceptance_rate: string;
    active_sessions: number;
    total_sessions: number;
  };
}

export function useAgentMetrics(params?: { agent_type?: string; days?: number }) {
  return useQuery({
    queryKey: ["agent-orchestration", "metrics", params],
    queryFn: async ({ signal }) => {
      const query = new URLSearchParams();
      if (params?.agent_type) query.set("agent_type", params.agent_type);
      if (params?.days) query.set("days", String(params.days));

      return fetchAPI(`/metrics?${query.toString()}`, { signal });
    },
  });
}
