import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import morgan from "morgan";
import path from "path";
import { fileURLToPath } from "url";

import { connectToMongo } from "./lib/db.js";
import { apiRouter } from "./routes/index.js";
import { errorHandler } from "./middleware/errorHandler.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// PUBLIC_INTERFACE
/**
 * Starts the monolith:
 * - Internal API server on INTERNAL_API_PORT (default 8000)
 * - Frontend on PORT (default 3000). In dev, served via Vite middleware; in prod, serves /dist.
 */
export async function start() {
  const nodeEnv = process.env.NODE_ENV || "development";
  const publicPort = Number(process.env.PORT || 3000);
  const apiPort = Number(process.env.INTERNAL_API_PORT || 8000);

  await connectToMongo();

  // Internal API app
  const apiApp = express();
  apiApp.use(cors());
  apiApp.use(express.json({ limit: "1mb" }));
  apiApp.use(morgan("dev"));

  apiApp.get("/api/health", (req, res) => {
    res.json({ ok: true, service: "mobile-service-hub", env: nodeEnv });
  });

  apiApp.use("/api", apiRouter);
  apiApp.use(errorHandler);

  apiApp.listen(apiPort, "127.0.0.1", () => {
    // eslint-disable-next-line no-console
    console.log(`[api] listening on http://127.0.0.1:${apiPort}`);
  });

  // Public web app
  const app = express();
  app.use(cors());

  if (nodeEnv === "production") {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  } else {
    // Dev: Vite middleware provides HMR and serves the SPA.
    const { createServer: createViteServer } = await import("vite");
    const vite = await createViteServer({
      root: process.cwd(),
      server: { middlewareMode: true, port: publicPort }
    });
    app.use(vite.middlewares);
  }

  app.listen(publicPort, "0.0.0.0", () => {
    // eslint-disable-next-line no-console
    console.log(`[web] listening on http://0.0.0.0:${publicPort}`);
  });
}

start().catch((err) => {
  // eslint-disable-next-line no-console
  console.error("Failed to start server:", err);
  process.exit(1);
});
