/**
 * Bun test framework shim for Node.js/Vitest compatibility
 *
 * This provides a compatibility layer for bun:test imports
 * when running on Node.js with Vitest
 */

import { describe, test, expect, beforeEach, afterEach, beforeAll, afterAll, vi } from "vitest"

// Mock/spy functions
const mock = vi.fn
const spyOn = vi.spyOn

export { describe, test, expect, beforeEach, afterEach, beforeAll, afterAll, mock, spyOn }

// Default export for compatibility
export default { describe, test, expect, beforeEach, afterEach, beforeAll, afterAll, mock, spyOn }
