import { Plugin } from "@opencode/plugin"
import { spawn } from "node:child_process"

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// `rtk rewrite` signals its result through the exit code, not just stdout:
//   3 = a rewrite was produced and written to stdout
//   1 = no rewrite applies, stdout is empty
// It exits non-zero even on success, so this must not use execFile, which
// rejects on any non-zero exit and would silently discard every rewrite.

const REWRITE_EXIT = 3

function rewrite(command: string, signal?: AbortSignal): Promise<string | undefined> {
  return new Promise((resolve) => {
    const child = spawn("rtk", ["rewrite", command], { signal })
    let stdout = ""
    let stderr = ""

    child.stdout.on("data", (d) => (stdout += d))
    child.stderr.on("data", (d) => (stderr += d))

    child.on("error", () => resolve(undefined))

    child.on("close", (code) => {
      if (code === REWRITE_EXIT) {
        const rewritten = stdout.trim()
        resolve(rewritten && rewritten !== command ? rewritten : undefined)
        return
      }
      if (stderr.trim()) {
        console.warn(`[rtk] rewrite failed: ${stderr.trim()}`)
      }
      resolve(undefined)
    })
  })
}

export default Plugin.define({
  id: "rtk",
  async setup(ctx) {
    const available = await new Promise<boolean>((resolve) => {
      const child = spawn("rtk", ["--version"])
      child.on("error", () => resolve(false))
      child.on("close", (code) => resolve(code === 0))
    })

    if (!available) {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String(event.tool).toLowerCase()
      if (tool !== "bash" && tool !== "shell") return

      const args = event.input as Record<string, unknown> | undefined
      if (!args || typeof args !== "object") return

      const command = args.command
      if (typeof command !== "string" || !command) return

      const rewritten = await rewrite(command)
      if (rewritten) args.command = rewritten
    })
  },
})
