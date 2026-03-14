import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    // Ensure Turbopack stays scoped to the frontend workspace.
    // This avoids workspace-root auto-detection issues when multiple lockfiles exist.
    root: process.cwd()
  }
};

export default nextConfig;
