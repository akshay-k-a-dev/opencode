/**
 * Bun API shims for Node.js compatibility on ARM7L
 *
 * This module provides Node.js implementations of Bun-specific APIs
 * so OpenCode can run on ARM7L systems without Bun.
 */

import { readFile, writeFile, stat, access, mkdir } from "fs/promises"
import { createReadStream } from "fs"
import { glob } from "glob"
import { resolve, dirname } from "path"
import { fileURLToPath } from "url"

// Polyfill for __dirname in ES modules
const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

/**
 * Bun.file() shim - Returns an object with file operations
 */
export function BunFile(path: string) {
  return {
    async text(): Promise<string> {
      return readFile(path, "utf-8")
    },

    async json(): Promise<any> {
      const content = await readFile(path, "utf-8")
      return JSON.parse(content)
    },

    async arrayBuffer(): Promise<ArrayBuffer> {
      const buffer = await readFile(path)
      return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength)
    },

    async bytes(): Promise<Uint8Array> {
      return readFile(path)
    },

    async blob(): Promise<Blob> {
      const buffer = await readFile(path)
      return new Blob([buffer])
    },

    async exists(): Promise<boolean> {
      try {
        await access(path)
        return true
      } catch {
        return false
      }
    },

    async size(): Promise<number> {
      try {
        const s = await stat(path)
        return s.size
      } catch {
        return 0
      }
    },

    stream(): ReadableStream<Uint8Array> {
      const nodeStream = createReadStream(path)
      return new ReadableStream({
        start(controller) {
          nodeStream.on("data", (chunk: Buffer) => {
            controller.enqueue(new Uint8Array(chunk))
          })
          nodeStream.on("end", () => {
            controller.close()
          })
          nodeStream.on("error", (err: Error) => {
            controller.error(err)
          })
        },
        cancel() {
          nodeStream.destroy()
        },
      })
    },

    async lastModified(): Promise<Date> {
      const s = await stat(path)
      return s.mtime
    },
  }
}

/**
 * Bun.write() shim
 */
export async function BunWrite(path: string, data: string | Buffer | Uint8Array | ArrayBuffer): Promise<number> {
  // Ensure directory exists
  const dir = dirname(path)
  try {
    await mkdir(dir, { recursive: true })
  } catch {
    // Directory might already exist
  }

  let buffer: Buffer
  if (typeof data === "string") {
    buffer = Buffer.from(data)
  } else if (data instanceof ArrayBuffer) {
    buffer = Buffer.from(data)
  } else if (ArrayBuffer.isView(data)) {
    buffer = Buffer.from(data.buffer, data.byteOffset, data.byteLength)
  } else {
    buffer = Buffer.from(data)
  }

  await writeFile(path, buffer)
  return buffer.length
}

/**
 * Bun.Glob shim
 */
export class BunGlob {
  private pattern: string

  constructor(pattern: string) {
    this.pattern = pattern
  }

  async *scan(options?: { cwd?: string; onlyFiles?: boolean; absolute?: boolean }): AsyncIterable<string> {
    const cwd = options?.cwd || process.cwd()
    const files = await glob(this.pattern, {
      cwd,
      absolute: options?.absolute ?? false,
      nodir: options?.onlyFiles ?? true,
    })

    for (const file of files) {
      yield file
    }
  }

  scanSync(options?: { cwd?: string; onlyFiles?: boolean; absolute?: boolean }): Iterable<string> {
    const cwd = options?.cwd || process.cwd()
    const files = glob.sync(this.pattern, {
      cwd,
      absolute: options?.absolute ?? false,
      nodir: options?.onlyFiles ?? true,
    })

    return files
  }
}

/**
 * Bun.spawn shim
 */
export async function BunSpawn(
  command: string[],
  options?: {
    cwd?: string
    env?: Record<string, string>
    stdio?: "inherit" | "pipe"
  },
) {
  const { spawn } = await import("child_process")

  return new Promise((resolve, reject) => {
    const child = spawn(command[0], command.slice(1), {
      cwd: options?.cwd,
      env: { ...process.env, ...options?.env },
      stdio: options?.stdio || "inherit",
    })

    let stdout = ""
    let stderr = ""

    if (child.stdout) {
      child.stdout.on("data", (data) => {
        stdout += data
      })
    }

    if (child.stderr) {
      child.stderr.on("data", (data) => {
        stderr += data
      })
    }

    child.on("close", (code) => {
      resolve({
        exitCode: code,
        stdout,
        stderr,
      })
    })

    child.on("error", reject)
  })
}

/**
 * Main Bun shim object
 */
export const Bun = {
  file: BunFile,
  write: BunWrite,
  Glob: BunGlob,
  spawn: BunSpawn,

  // Environment
  env: process.env,

  // Version info
  version: "0.0.0-arm7l-node-shim",

  // Runtime detection
  get runtime() {
    return "node" as const
  },

  // Platform info
  get platform() {
    return {
      linux: process.platform === "linux",
      darwin: process.platform === "darwin",
      win32: process.platform === "win32",
    }
  },
}

// Export individual functions for convenience
export { BunFile as file, BunWrite as write, BunGlob as Glob, BunSpawn as spawn }
export default Bun

// Make Bun available globally
declare global {
  var Bun: typeof Bun
}

globalThis.Bun = Bun
console.log("[ARM7L] Bun shims loaded successfully")
