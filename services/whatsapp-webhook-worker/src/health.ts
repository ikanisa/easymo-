import { createClient } from "@supabase/supabase-js";
import Redis from "ioredis";
import { OpenAI } from "openai";

import { config } from "./config.js";
import { logger } from "./logger.js";
import type { WebhookWorker } from "./worker.js";

export type ProbeStatus = "ok" | "fail";

export interface ProbeResult {
  status: ProbeStatus;
  latencyMs: number;
  error?: string;
  statusCode?: number;
}

export interface HealthReport {
  status: "ok" | "degraded" | "critical";
  timestamp: string;
  uptime: number;
  checks: {
    openai: ProbeResult;
    redis: ProbeResult;
    supabase: ProbeResult;
  };
  worker: {
    running: boolean;
    metrics: ReturnType<WebhookWorker["getMetrics"]>;
  };
}

const openAIClient = new OpenAI({
  apiKey: config.OPENAI_API_KEY,
  baseURL: config.OPENAI_BASE_URL || undefined,
});

const supabaseClient = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_SERVICE_ROLE_KEY
);

async function runOpenAIProbe(): Promise<ProbeResult> {
  const started = Date.now();
  try {
    await openAIClient.chat.completions.create({
      model: config.OPENAI_MODEL,
      messages: [{ role: "user", content: "ping" }],
      max_tokens: 1,
    });
    return { status: "ok", latencyMs: Date.now() - started };
  } catch (error) {
    const latency = Date.now() - started;
    const statusCode = typeof (error as any)?.status === "number" ? (error as any).status : undefined;
    const message = error instanceof Error ? error.message : String(error);
    logger.error({ event: "health.openai.failed", error: message, statusCode });
    return { status: "fail", latencyMs: latency, error: message, statusCode };
  }
}

async function runRedisProbe(): Promise<ProbeResult> {
  const client = new Redis(config.REDIS_URL, {
    lazyConnect: true,
    connectTimeout: 2_000,
    maxRetriesPerRequest: 1,
  });
  const started = Date.now();
  try {
    await client.connect();
    const response = await client.ping();
    const latency = Date.now() - started;
    if ((response ?? "").toString().toUpperCase() !== "PONG") {
      const error = `Unexpected Redis PING response: ${response}`;
      logger.error({ event: "health.redis.failed", error });
      return { status: "fail", latencyMs: latency, error };
    }
    return { status: "ok", latencyMs: latency };
  } catch (error) {
    const latency = Date.now() - started;
    const message = error instanceof Error ? error.message : String(error);
    logger.error({ event: "health.redis.failed", error: message });
    return { status: "fail", latencyMs: latency, error: message };
  } finally {
    try {
      if (client.status !== "end") {
        await client.quit();
      }
    } catch (quitError) {
      logger.warn({ event: "health.redis.cleanup_failed", error: String(quitError) });
    }
  }
}

async function runSupabaseProbe(): Promise<ProbeResult> {
  const started = Date.now();
  try {
    const { error, status } = await supabaseClient
      .from("wa_interactions")
      .select("id", { count: "exact" })
      .limit(1);

    const latency = Date.now() - started;
    if (error) {
      const message = error.message ?? "Unknown Supabase error";
      logger.error({ event: "health.supabase.failed", error: message, status });
      return {
        status: "fail",
        latencyMs: latency,
        error: message,
        statusCode: typeof status === "number" ? status : undefined,
      };
    }

    if (typeof status === "number" && status >= 400) {
      logger.error({
        event: "health.supabase.failed_status",
        status,
      });
      return {
        status: "fail",
        latencyMs: latency,
        statusCode: status,
        error: `Unexpected Supabase status ${status}`,
      };
    }

    return { status: "ok", latencyMs: latency };
  } catch (error) {
    const latency = Date.now() - started;
    const message = error instanceof Error ? error.message : String(error);
    const statusCode = typeof (error as any)?.status === "number" ? (error as any).status : undefined;
    logger.error({ event: "health.supabase.failed", error: message, statusCode });
    return { status: "fail", latencyMs: latency, error: message, statusCode };
  }
}

function deriveOverallStatus(results: ProbeResult[]): HealthReport["status"] {
  const failures = results.filter((result) => result.status === "fail");
  if (failures.length === 0) {
    return "ok";
  }
  if (failures.length === results.length) {
    return "critical";
  }
  return "degraded";
}

export async function buildHealthReport(worker: WebhookWorker): Promise<HealthReport> {
  const [openai, redis, supabase] = await Promise.all([
    runOpenAIProbe(),
    runRedisProbe(),
    runSupabaseProbe(),
  ]);

  const status = deriveOverallStatus([openai, redis, supabase]);

  return {
    status,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    checks: {
      openai,
      redis,
      supabase,
    },
    worker: {
      running: worker.isStarted(),
      metrics: worker.getMetrics(),
    },
  };
}
