import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Vite dev server runs on :3000 (preview requirement).
// We proxy /api to the Express API that is started on a separate internal port.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    strictPort: true,
    proxy: {
      "/api": {
        target: process.env.INTERNAL_API_URL || "http://127.0.0.1:8000",
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: "dist",
    sourcemap: process.env.ENABLE_SOURCE_MAPS === "true"
  }
});
