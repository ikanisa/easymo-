// deno-lint-ignore-file no-explicit-any
import { serve } from "$std/http/server.ts";
import { createHash } from "$std/hash/mod.ts";
import { getServiceClient } from "shared/supabase.ts";
import { ok, serverError } from "shared/http.ts";

const DAY_MS = 24 * 60 * 60 * 1000;
const supabase = getServiceClient();
const denoWithCron = Deno as typeof Deno & {
  cron?: (name: string, schedule: string, handler: () => void | Promise<void>) => void;
};

const CRON_EXPR = Deno.env.get("DATA_RETENTION_CRON") ?? "0 2 * * *";
const CRON_ENABLED = (Deno.env.get("DATA_RETENTION_CRON_ENABLED") ?? "true").toLowerCase() !== "false";
const VOUCHER_RETENTION_DAYS = Number(Deno.env.get("VOUCHER_RETENTION_DAYS") ?? "90");
const CAMPAIGN_TARGET_RETENTION_DAYS = Number(Deno.env.get("CAMPAIGN_TARGET_RETENTION_DAYS") ?? "30");
const INSURANCE_DOC_RETENTION_DAYS = Number(Deno.env.get("INSURANCE_DOC_RETENTION_DAYS") ?? "30");
const INSURANCE_BUCKET = Deno.env.get("INSURANCE_MEDIA_BUCKET") ?? "insurance-docs";
const FINAL_INSURANCE_STATUSES = ["completed", "rejected"];

function maskMsisdn(input?: string | null): string {
  const trimmed = (input ?? "").trim();
  if (!trimmed) return "—";
  const startsWithPlus = trimmed.startsWith("+");
  const digits = trimmed.replace(/[^0-9]/g, "");
  if (digits.length < 4) return trimmed;
  const suffixLength = digits.length >= 7 ? 3 : Math.min(2, digits.length - 1);
  const prefixLength = Math.min(5, Math.max(2, digits.length - suffixLength - 1));
  const maskedCount = digits.length - prefixLength - suffixLength;
  if (maskedCount <= 0) {
    const base = startsWithPlus ? `+${digits}` : digits;
    return startsWithPlus
      ? `+${base.slice(1).replace(/(.{1,3})/g, "$1 ").trim()}`
      : base.replace(/(.{1,3})/g, "$1 ").trim();
  }
  const prefix = digits.slice(0, prefixLength);
  const suffix = digits.slice(-suffixLength);
  const maskedDigits = `${prefix}${"*".repeat(maskedCount)}${suffix}`;
  const withPlus = startsWithPlus ? `+${maskedDigits}` : maskedDigits;
  const body = startsWithPlus ? withPlus.slice(1) : withPlus;
  const grouped = body.replace(/(.{1,3})/g, "$1 ").trim();
  return startsWithPlus ? `+${grouped}` : grouped;
}

function hashMsisdn(input?: string | null): string {
  const normalized = (input ?? "").trim();
  const hash = createHash("sha256");
  hash.update(normalized);
  return hash.toString();
}

function normalizeStoragePath(path?: string | null): string | null {
  if (!path) return null;
  if (path.startsWith(`${INSURANCE_BUCKET}/`)) {
    return path.slice(INSURANCE_BUCKET.length + 1);
  }
  return path;
}

async function purgeExpiredVouchers(now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - VOUCHER_RETENTION_DAYS * DAY_MS).toISOString();
  const { count, error } = await supabase
    .from("vouchers")
    .delete()
    .eq("status", "expired")
    .lte("expires_at", cutoff)
    .select("id", { count: "exact" });
  if (error) {
    throw new Error(`voucher_purge_failed: ${error.message}`);
  }
  return count ?? 0;
}

async function archiveCampaignTargets(now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - CAMPAIGN_TARGET_RETENTION_DAYS * DAY_MS).toISOString();
  const batchSize = 200;
  let archived = 0;
  while (true) {
    const { data, error } = await supabase
      .from("campaign_targets")
      .select(`
        id,
        campaign_id,
        msisdn,
        status,
        error_code,
        last_update_at,
        campaigns!inner(id, finished_at)
      `)
      .lte("campaigns.finished_at", cutoff)
      .limit(batchSize);
    if (error) {
      throw new Error(`campaign_targets_fetch_failed: ${error.message}`);
    }
    if (!data || data.length === 0) break;

    const records = data.map((row) => ({
      target_id: row.id,
      campaign_id: row.campaign_id,
      msisdn_hash: hashMsisdn(row.msisdn),
      msisdn_masked: maskMsisdn(row.msisdn),
      status: row.status,
      error_code: row.error_code,
      last_update_at: row.last_update_at,
      metadata: { archived_by: "data-retention" },
    }));

    const { error: upsertErr } = await supabase
      .from("campaign_target_archives")
      .upsert(records, { onConflict: "target_id" });
    if (insertErr) {
      throw new Error(`campaign_targets_archive_insert_failed: ${insertErr.message}`);
    }

    const ids = data.map((row) => row.id);
    const { error: deleteErr } = await supabase
      .from("campaign_targets")
      .delete()
      .in("id", ids);
    if (deleteErr) {
      throw new Error(`campaign_targets_delete_failed: ${deleteErr.message}`);
    }

    archived += data.length;
    if (data.length < batchSize) break;
  }
  return archived;
}

async function deleteInsuranceDocuments(now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - INSURANCE_DOC_RETENTION_DAYS * DAY_MS).toISOString();
  const batchSize = 200;
  let deleted = 0;

  while (true) {
    const { data, error } = await supabase
      .from("insurance_documents")
      .select(`
        id,
        storage_path,
        intent:insurance_intents!inner(status, updated_at)
      `)
      .in("intent.status", FINAL_INSURANCE_STATUSES)
      .lte("intent.updated_at", cutoff)
      .limit(batchSize);
    if (error) {
      throw new Error(`insurance_documents_fetch_failed: ${error.message}`);
    }
    if (!data || data.length === 0) break;

    const storagePaths = data
      .map((doc) => normalizeStoragePath(doc.storage_path))
      .filter((value): value is string => Boolean(value));

    if (storagePaths.length) {
      const { error: storageErr } = await supabase.storage
        .from(INSURANCE_BUCKET)
        .remove(storagePaths);
      if (storageErr) {
        throw new Error(`insurance_storage_delete_failed: ${storageErr.message}`);
      }
    }

    const ids = data.map((doc) => doc.id);
    const { error: deleteErr } = await supabase
      .from("insurance_documents")
      .delete()
      .in("id", ids);
    if (deleteErr) {
      throw new Error(`insurance_documents_delete_failed: ${deleteErr.message}`);
    }

    deleted += data.length;
    if (data.length < batchSize) break;
  }

  return deleted;
}

async function runRetention(trigger: "http" | "cron") {
  const now = new Date();
  const summary: Record<string, unknown> = {
    trigger,
    timestamp: now.toISOString(),
  };

  try {
    const [vouchersPurged, targetsArchived, insuranceDeleted] = await Promise.all([
      purgeExpiredVouchers(now),
      archiveCampaignTargets(now),
      deleteInsuranceDocuments(now),
    ]);

    summary.vouchers_purged = vouchersPurged;
    summary.campaign_targets_archived = targetsArchived;
    summary.insurance_documents_deleted = insuranceDeleted;
    summary.ok = true;
    console.info("data_retention.completed", summary);
    return summary;
  } catch (error) {
    console.error("data_retention.failed", error);
    return {
      ok: false,
      trigger,
      timestamp: now.toISOString(),
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

serve(async (_req) => {
  const result = await runRetention("http");
  if (result.ok) {
    return ok(result);
  }
  return serverError("data_retention_failed", result);
});

if (typeof denoWithCron.cron === "function" && CRON_ENABLED) {
  denoWithCron.cron("data-retention", CRON_EXPR, async () => {
    try {
      await runRetention("cron");
    } catch (error) {
      console.error("data_retention.cron_failed", error);
    }
  });
} else if (!CRON_ENABLED) {
  console.warn("data-retention cron disabled via env");
}
