import { z } from "zod";
import { jsonOk, jsonError } from "@/lib/api/http";
import { createHandler } from "@/app/api/withObservability";
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

export const dynamic = "force-dynamic";

// Update session schema
const updateSessionSchema = z.object({
  status: z.enum(["searching", "negotiating", "completed", "timeout", "cancelled"]).optional(),
  selected_quote_id: z.string().uuid().optional(),
  cancellation_reason: z.string().optional(),
  extend_deadline: z.boolean().optional(),
});

// GET /api/agent-orchestration/sessions/[id] - Get session detail
export const GET = createHandler<{ params: Promise<{ id: string }> }>(
  "admin_api.agent_sessions.detail",
  async (req, context) => {
    try {
      const { id } = await context.params;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const { data: session, error: sessionError } = await supabase
        .from("agent_sessions")
        .select("*")
        .eq("id", id)
        .single();

      if (sessionError || !session) {
        return jsonError(
          { error: "not_found", message: "Session not found" },
          404
        );
      }

      // Fetch the agent registry configuration to include max extension limits
      const { data: agentConfig, error: agentConfigError } = await supabase
        .from("agent_registry")
        .select("max_extensions")
        .eq("agent_type", session.agent_type)
        .single();

      if (agentConfigError) {
        console.warn("Failed to load agent config for session", id, agentConfigError);
      }

      // Fetch quotes for this session
      const { data: quotes, error: quotesError } = await supabase
        .from("agent_quotes")
        .select("*")
        .eq("session_id", id)
        .order("responded_at", { ascending: false });

      if (quotesError) {
        console.error("Failed to fetch quotes:", quotesError);
      }

      return jsonOk({
        session: {
          ...session,
          max_extensions: agentConfig?.max_extensions ?? 2,
        },
        quotes: quotes || [],
      });
    } catch (error) {
      console.error("Agent session detail error:", error);
      return jsonError({ error: "internal_error", message: "Internal server error" }, 500);
    }
});

// PATCH /api/agent-orchestration/sessions/[id] - Update session
export const PATCH = createHandler<{ params: Promise<{ id: string }> }>(
  "admin_api.agent_sessions.update",
  async (req, context) => {
    try {
      const { id } = await context.params;
      const body = await req.json();
      const validated = updateSessionSchema.parse(body);

      const supabase = createClient(supabaseUrl, supabaseKey);

      // First, get the current session
      const { data: currentSession, error: fetchError } = await supabase
        .from("agent_sessions")
        .select("*")
        .eq("id", id)
        .single();

      if (fetchError || !currentSession) {
        return jsonError(
          { error: "not_found", message: "Session not found" },
          404
        );
      }

      const { data: agentConfig, error: agentConfigError } = await supabase
        .from("agent_registry")
        .select("max_extensions")
        .eq("agent_type", currentSession.agent_type)
        .single();

      if (agentConfigError) {
        console.warn("Failed to load agent config for session", id, agentConfigError);
      }

      const maxExtensions = agentConfig?.max_extensions ?? 2;

      const updates: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
      };

      if (validated.status) {
        updates.status = validated.status;
        if (validated.status === "completed" || validated.status === "timeout" || validated.status === "cancelled") {
          updates.completed_at = new Date().toISOString();
        }
      }

      if (validated.selected_quote_id) {
        updates.selected_quote_id = validated.selected_quote_id;
      }

      if (validated.cancellation_reason) {
        updates.cancellation_reason = validated.cancellation_reason;
      }

      // Handle deadline extension
      if (validated.extend_deadline && currentSession.extensions_count < maxExtensions) {
        const newDeadline = new Date(currentSession.deadline_at);
        newDeadline.setMinutes(newDeadline.getMinutes() + 2);
        updates.deadline_at = newDeadline.toISOString();
        updates.extensions_count = currentSession.extensions_count + 1;
      }

      const { data, error } = await supabase
        .from("agent_sessions")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) {
        console.error("Failed to update agent session:", error);
        return jsonError(
          { error: "update_failed", message: "Failed to update agent session" },
          500
        );
      }

      return jsonOk({
        session: {
          ...data,
          max_extensions: maxExtensions,
        },
      });
    } catch (error) {
      if (error instanceof z.ZodError) {
        return jsonError(
          { error: "invalid_payload", message: error.flatten() },
          400
        );
      }
      console.error("Agent session update error:", error);
      return jsonError({ error: "internal_error", message: "Internal server error" }, 500);
    }
});
