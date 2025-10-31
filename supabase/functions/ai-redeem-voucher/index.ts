import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  isAgentVoucherFeatureEnabled,
  verifyAgentToolAuth,
} from "../_shared/agent-auth.ts";

/**
 * AI Agent Tool: Redeem Voucher
 * Redeems an issued voucher by updating its status
 */

interface RedeemVoucherRequest {
  voucher_id: string;
  customer_msisdn: string;
}

interface RedeemVoucherResponse {
  success: boolean;
  voucher_id?: string;
  status?: string;
  redeemed_at?: string;
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
          event: "ai.tool.redeem_voucher.feature_disabled",
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
          event: "ai.tool.redeem_voucher.unauthorized",
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
    const body: RedeemVoucherRequest = await req.json();
    const { voucher_id, customer_msisdn } = body;

    // Validation
    if (!voucher_id || typeof voucher_id !== "string") {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid voucher_id" }),
        { status: 400, headers: JSON_HEADERS }
      );
    }

    if (!customer_msisdn || typeof customer_msisdn !== "string") {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid customer_msisdn" }),
        { status: 400, headers: JSON_HEADERS }
      );
    }

    // Log request (with PII masking)
    console.log(
      JSON.stringify({
        event: "ai.tool.redeem_voucher.start",
        correlation_id: correlationId,
        voucher_id,
        msisdn_masked: customer_msisdn.substring(0, 5) + "***" + customer_msisdn.slice(-3),
        timestamp: new Date().toISOString(),
      })
    );

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Check voucher exists and belongs to customer
    const { data: voucher, error: fetchError } = await supabase
      .from("vouchers")
      .select("id, status, whatsapp_e164")
      .eq("id", voucher_id)
      .single();

    if (fetchError || !voucher) {
      console.error(
        JSON.stringify({
          event: "ai.tool.redeem_voucher.not_found",
          correlation_id: correlationId,
          voucher_id,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Voucher not found",
        } as RedeemVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    // Check voucher belongs to customer
    if (voucher.whatsapp_e164 !== customer_msisdn) {
      console.error(
        JSON.stringify({
          event: "ai.tool.redeem_voucher.unauthorized",
          correlation_id: correlationId,
          voucher_id,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: "Voucher does not belong to this customer",
        } as RedeemVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    // Check voucher status
    if (voucher.status !== "issued") {
      console.error(
        JSON.stringify({
          event: "ai.tool.redeem_voucher.invalid_status",
          correlation_id: correlationId,
          voucher_id,
          current_status: voucher.status,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: `Voucher cannot be redeemed (current status: ${voucher.status})`,
        } as RedeemVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    // Redeem voucher
    const redeemedAt = new Date().toISOString();
    const { data, error } = await supabase
      .from("vouchers")
      .update({
        status: "redeemed",
        redeemed_at: redeemedAt,
      })
      .eq("id", voucher_id)
      .select()
      .single();

    if (error) {
      console.error(
        JSON.stringify({
          event: "ai.tool.redeem_voucher.error",
          correlation_id: correlationId,
          error: error.message,
        })
      );

      return new Response(
        JSON.stringify({
          success: false,
          error: error.message,
        } as RedeemVoucherResponse),
        { status: 200, headers: JSON_HEADERS }
      );
    }

    const response: RedeemVoucherResponse = {
      success: true,
      voucher_id: data.id,
      status: data.status,
      redeemed_at: data.redeemed_at,
    };

    // Log success
    console.log(
      JSON.stringify({
        event: "ai.tool.redeem_voucher.success",
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
        event: "ai.tool.redeem_voucher.exception",
        correlation_id: correlationId,
        error: String(err),
      })
    );

    return new Response(
      JSON.stringify({
        success: false,
        error: "Internal server error",
      } as RedeemVoucherResponse),
      { status: 500, headers: JSON_HEADERS }
    );
  }
});
