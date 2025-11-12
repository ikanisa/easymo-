import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  OmniSearchCategory,
  OmniSearchSuggestion,
} from "./types";

interface SuggestionOptions {
  limitPerCategory?: number;
  query?: string;
}

const DEFAULT_SUGGESTION_LIMIT = 4;

function normaliseQuery(query: string | undefined | null): string {
  return query?.trim().toLowerCase() ?? "";
}

function scoreSuggestion(input: string, query: string): number {
  if (!query) return 1;
  const haystack = input.toLowerCase();
  if (haystack.startsWith(query)) return 3;
  if (haystack.includes(query)) return 2;
  return 1;
}

function createSuggestion(
  category: OmniSearchCategory,
  id: string,
  label: string,
  description: string | null,
  query: string,
): OmniSearchSuggestion {
  return {
    id: `${category}-${id}`,
    category,
    label,
    description,
    query,
  };
}

export async function fetchOmniSearchSuggestions(
  supabase: SupabaseClient,
  { limitPerCategory = DEFAULT_SUGGESTION_LIMIT, query }: SuggestionOptions = {},
): Promise<OmniSearchSuggestion[]> {
  const normalizedQuery = normaliseQuery(query);
  const likePattern = normalizedQuery ? `%${normalizedQuery}%` : null;

  const agentsQuery = supabase
    .from("agent_registry")
    .select("id, agent_type, name, description");
  const requestsQuery = supabase
    .from("agent_sessions")
    .select("id, agent_type, status");
  const policiesQuery = supabase
    .from("settings")
    .select("key, description");
  const tasksQuery = supabase
    .from("agent_tasks")
    .select("id, title, status");

  const filteredAgentsQuery = likePattern
    ? agentsQuery.or(`name.ilike.${likePattern},agent_type.ilike.${likePattern}`)
    : agentsQuery;
  const filteredRequestsQuery = likePattern
    ? requestsQuery.ilike("agent_type", likePattern)
    : requestsQuery;
  const filteredPoliciesQuery = likePattern
    ? policiesQuery.ilike("key", likePattern)
    : policiesQuery;
  const filteredTasksQuery = likePattern
    ? tasksQuery.or(`title.ilike.${likePattern},status.ilike.${likePattern}`)
    : tasksQuery;

  const [agentsRes, requestsRes, policiesRes, tasksRes] = await Promise.allSettled([
    filteredAgentsQuery
      .order("updated_at", { ascending: false })
      .limit(limitPerCategory),
    filteredRequestsQuery
      .order("started_at", { ascending: false })
      .limit(limitPerCategory),
    filteredPoliciesQuery
      .order("updated_at", { ascending: false })
      .limit(limitPerCategory),
    filteredTasksQuery
      .order("created_at", { ascending: false })
      .limit(limitPerCategory),
  ]);

  const suggestions: OmniSearchSuggestion[] = [];

  if (agentsRes.status === "fulfilled" && !agentsRes.value.error) {
    for (const row of agentsRes.value.data ?? []) {
      const display = row.name ?? row.agent_type;
      suggestions.push(
        createSuggestion(
          "agent",
          row.id,
          display,
          row.description ?? null,
          row.name ?? row.agent_type,
        ),
      );
    }
  }

  if (requestsRes.status === "fulfilled" && !requestsRes.value.error) {
    for (const row of requestsRes.value.data ?? []) {
      const display = row.agent_type ?? "Session";
      suggestions.push(
        createSuggestion(
          "request",
          row.id,
          `${display} · ${row.status}`,
          row.status ?? null,
          display,
        ),
      );
    }
  }

  if (policiesRes.status === "fulfilled" && !policiesRes.value.error) {
    for (const row of policiesRes.value.data ?? []) {
      suggestions.push(
        createSuggestion(
          "policy",
          row.key,
          row.key,
          row.description ?? null,
          row.key,
        ),
      );
    }
  }

  if (tasksRes.status === "fulfilled" && !tasksRes.value.error) {
    for (const row of tasksRes.value.data ?? []) {
      suggestions.push(
        createSuggestion(
          "task",
          row.id,
          row.title ?? `Task ${row.id.slice(0, 6)}`,
          row.status ?? null,
          row.title ?? row.status ?? "",
        ),
      );
    }
  }

  if (!normalizedQuery) {
    return suggestions;
  }

  return suggestions
    .map((suggestion) => ({
      suggestion,
      score: scoreSuggestion(suggestion.label, normalizedQuery),
    }))
    .sort((a, b) => b.score - a.score)
    .map((entry) => entry.suggestion);
}
