import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  isAgentVoucherFeatureEnabled,
  verifyAgentToolAuth,
} from "../_shared/agent-auth.ts";

/**
 * AI Agent Tool: Void Voucher
 * Voids/cancels an issued voucher that hasn't been redeemed
 */

interface VoidVoucherRequest {
  voucher_id: string;
  reason?: string;
}

interface VoidVoucherResponse {
  success: boolean;
  voucher_id?: string;
  status?: string;
  voided_at?: string;
  error?: string;
}

const JSON_HEADERS: Record<string, string> = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
};

serve(async (req: Request): Promise<Response> => {
  const correlationId = crypto.randomUUID();

  try {
    // CORS handling
    if (req.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type, Authorization, X-Agent-JWT, X-Agent-Token, X-Admin-Token",
        },
      });
    }

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ success: false, error: "Method not allowed" }),
        { status: 405, headers: JSON_HEADERS }
      );
    }

    if (!isAgentVoucherFeatureEnabled()) {
      console.log(
        JSON.stringify({
          event: "ai.tool.void_voucher.feature_disabled",
          correlation_id: correlationId,
          timestamp: new Date().toISOString(),
        })
      );

      return new Response(
        JSON.stringify({ success: false, error: "feature_disabled" }),
        { status: 403, headers: JSON_HEADERS }
      );
    }

    if (!verifyAgentToolAuth(req, correlationId)) {
      console.warn(
        JSON.stringify({
          event: "ai.tool.void_voucher.unauthorized",
          correlation_id: correlationId,
          timestamp: new Date().toISOString(),
        })
      );

      return new Response(
        JSON.stringify({ success: false, error: "unauthorized" }),
        { status: 401, headers: JSON_HEADERS }
      );
    }

    // Parse request
    const body: VoidVoucherRequest = await req.json();
    const { voucher_id, reason } = body;

    // Validation
    if (!voucher_id || typeof voucher_id !== "string") {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid voucher_id" }),
        { status: 400, headers: JSON_HEADERS }
      );
    }

    // Log request
    console.log(
      JSON.stringify({
        event: "ai.tool.void_voucher.start",
        correlation_id: correlationId,
        voucher_id,
        has_reason: !!reason,
        timestamp: new Date().toISOString(),
      })
    );

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Check voucher exists
    const { data: voucher, error: fetchError } = await supabase
      .from("vouchers")
      .select("id, status")
      .eq("id", voucher_id)
      .single();

    if (fetchError || !voucher) {
      console.error(
        JSON.stringify({
          event: "ai.tool.void_voucher.not_found",
          correlation_id: correlationId,
          voucher_id,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Voucher not found",
        } as VoidVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    // Check voucher status - can only void issued vouchers
    if (voucher.status !== "issued") {
      console.error(
        JSON.stringify({
          event: "ai.tool.void_voucher.invalid_status",
          correlation_id: correlationId,
          voucher_id,
          current_status: voucher.status,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: `Voucher cannot be voided (current status: ${voucher.status})`,
        } as VoidVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    // Void voucher
    const voidedAt = new Date().toISOString();
    const notes = reason ? `Voided: ${reason}` : "Voided by AI agent";
    
    const { data, error } = await supabase
      .from("vouchers")
      .update({
        status: "void",
        notes,
        updated_at: voidedAt,
      })
      .eq("id", voucher_id)
      .select()
      .single();

    if (error) {
      console.error(
        JSON.stringify({
          event: "ai.tool.void_voucher.error",
          correlation_id: correlationId,
          error: error.message,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: error.message,
        } as VoidVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    const response: VoidVoucherResponse = {
      success: true,
      voucher_id: data.id,
      status: data.status,
      voided_at: data.updated_at,
    };

    // Log success
    console.log(
      JSON.stringify({
        event: "ai.tool.void_voucher.success",
        correlation_id: correlationId,
        voucher_id: data.id,
        timestamp: new Date().toISOString(),
      })
    );

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: JSON_HEADERS,
    });
  } catch (err) {
    console.error(
      JSON.stringify({
        event: "ai.tool.void_voucher.exception",
        correlation_id: correlationId,
        error: String(err),
      })
    );

    return new Response(
      JSON.stringify({
        success: false,
        error: "Internal server error",
      } as VoidVoucherResponse),
      { status: 500, headers: JSON_HEADERS }
    );
  }
});
