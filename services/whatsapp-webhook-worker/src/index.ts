import express from "express";
import pinoHttp from "pino-http";
import { config } from "./config.js";
import { logger } from "./logger.js";
import { WebhookWorker } from "./worker.js";
import { buildHealthReport } from "./health.js";

async function main() {
  logger.info({ config: { ...config, SUPABASE_SERVICE_ROLE_KEY: "***" } }, "Starting service");

  // Initialize worker
  const worker = new WebhookWorker();

  // Create health check server
  const app = express();
  app.use(express.json());
  app.use(pinoHttp({ logger: logger as any }));

  app.get("/health", async (_req, res) => {
    try {
      const report = await buildHealthReport(worker);
      const statusCode = report.status === "ok" ? 200 : 503;
      res.status(statusCode).json(report);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error({ event: "health.endpoint.failed", error: message });
      res.status(500).json({
        status: "critical",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        error: message,
      });
    }
  });

  app.get("/metrics", (_req, res) => {
    const metrics = worker.getMetrics();
    res.json(metrics);
  });

  const server = app.listen(Number(config.PORT), () => {
    logger.info({ port: config.PORT }, "Health check server listening");
  });

  // Start the worker
  await worker.start();

  // Graceful shutdown
  const shutdown = async () => {
    logger.info("Shutting down gracefully...");
    await worker.stop();
    server.close(() => {
      logger.info("Server closed");
      process.exit(0);
    });
  };

  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
}

main().catch((error) => {
  logger.error({ event: "fatal.error", error: error.message, stack: error.stack }, "Fatal error");
  process.exit(1);
});
