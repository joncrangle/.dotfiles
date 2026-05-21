// rtk-hook-version: 1
// RTK Pi extension — rewrites bash commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating extension: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// Exit code contract for `rtk rewrite`:
//   0 + stdout  Rewrite found → mutate command, allow
//   1           No RTK equivalent → pass through unchanged
//   2           Deny rule matched → block execution
//   3 + stdout  Ask rule matched → mutate command, allow (Pi has no confirm UI)

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

// Run a command, return { stdout, exitCode } or null on spawn error / timeout.
function exec(
  cmd: string,
  args: string[],
  timeoutMs = 2000,
): Promise<{ stdout: string; exitCode: number } | null> {
  return new Promise((resolve) => {
    let stdout = "";
    let settled = false;

    const child = spawn(cmd, args, { env: process.env });

    const timer = setTimeout(() => {
      if (!settled) {
        settled = true;
        child.kill();
        resolve(null);
      }
    }, timeoutMs);

    child.stdout.on("data", (chunk: Buffer) => {
      stdout += chunk.toString();
    });

    child.on("close", (code: number | null) => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        resolve({ stdout, exitCode: code ?? 1 });
      }
    });

    child.on("error", () => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        resolve(null);
      }
    });
  });
}

// Parse "X.Y.Z" semver, return [major, minor, patch] or null.
function parseSemver(raw: string): [number, number, number] | null {
  const m = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/);
  if (!m) return null;
  return [parseInt(m[1], 10), parseInt(m[2], 10), parseInt(m[3], 10)];
}

export default async function (pi: ExtensionAPI) {
  // Load-time check: probe rtk by running --version. This confirms the binary
  // is in PATH and gives us the version for the semver guard in one spawn.
  const ver = await exec("rtk", ["--version"]);
  if (!ver || ver.exitCode !== 0) {
    console.warn("[rtk] rtk binary not found in PATH — extension disabled");
    return;
  }

  // Load-time version guard: rtk rewrite was introduced in 0.23.0. Without
  // this check the extension still degrades gracefully — exec() returns null
  // on any subprocess failure, which falls through to pass-through behaviour.
  // The guard exists purely to surface a clear, actionable warning
  // ("your rtk is too old, upgrade") rather than leaving the user wondering
  // why rewrites silently stopped working after a version rollback.
  // stdout format: "rtk X.Y.Z"
  const parsed = parseSemver(ver.stdout.replace(/^rtk\s+/, ""));
  if (parsed) {
    const [major, minor] = parsed;
    if (major === 0 && minor < 23) {
      console.warn(
        `[rtk] rtk ${ver.stdout.trim()} is too old (need >= 0.23.0) — extension disabled`,
      );
      return;
    }
  }

  pi.on("tool_call", async (event) => {
    // Only intercept bash tool calls.
    if (!isToolCallEventType("bash", event)) return;

    const cmd = event.input.command;
    if (!cmd) return;

    if (cmd.startsWith("rtk ")) return;
    if (process.env.RTK_DISABLED === "1") return;

    // Delegate all rewrite + permission logic to the RTK.
    const result = await exec("rtk", ["rewrite", cmd]);
    if (!result) return; // spawn error or timeout — pass through

    const rewritten = result.stdout.trim();

    switch (result.exitCode) {
      case 0:
        // Rewrite found — mutate the command in-place.
        if (rewritten && rewritten !== cmd) {
          event.input.command = rewritten;
        }
        return;

      case 1:
        // No RTK equivalent — pass through unchanged.
        return;

      case 2:
        // Deny rule matched — block execution.
        return { block: true, reason: `RTK: '${cmd}' is blocked — see rtk gain for details` };

      case 3:
        // Ask rule matched — rewrite and allow (Pi has no per-tool confirm UI).
        if (rewritten && rewritten !== cmd) {
          event.input.command = rewritten;
        }
        return;

      default:
        return;
    }
  });
}
