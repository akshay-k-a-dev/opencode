import { defineConfig } from "vitest/config"

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["test/**/*.test.ts"],
    exclude: ["node_modules", "dist"],
    alias: {
      "bun:test": "./shims/bun-test-shim.ts",
      "bun:*": "./shims/bun-shim.ts",
    },
  },
  resolve: {
    alias: {
      "@opencode-ai/script": "../../packages/script/src",
      "@opencode-ai/util": "../../packages/util/src",
      "@opencode-ai/plugin": "../../packages/plugin/src",
      "@opencode-ai/sdk": "../../packages/sdk/js/src",
    },
  },
})
