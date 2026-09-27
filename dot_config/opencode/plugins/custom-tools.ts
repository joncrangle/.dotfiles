import { Plugin } from "@opencode/plugin";
import { spawn } from "node:child_process";

// =============================================================================
// Custom tools ported from the V1 `tool()` API to V2 tool transforms.
//
// Each tool declares `options.permission` so agents can still target it by name
// (e.g. `{action: "code_rewrite", resource: "*", effect: "deny"}`).
//
// Each also sets `options.codemode: false`. Without it, a plugin-registered tool
// gets folded into the Code Mode catalog and is reachable only through the
// `execute` indirection, which models tend to skip. Built-in tools stay
// direct/top-level; `codemode: false` opts these into the same treatment.
// =============================================================================

function spawnText(
  cmd: string[],
  signal?: AbortSignal,
): Promise<{ stdout: string; stderr: string; code: number }> {
  return new Promise((resolve) => {
    const child = spawn(cmd[0]!, cmd.slice(1), { signal });
    let stdout = "";
    let stderr = "";
    child.stdout?.on("data", (d) => (stdout += d));
    child.stderr?.on("data", (d) => (stderr += d));
    child.on("error", (e) => resolve({ stdout, stderr: String(e), code: 1 }));
    child.on("close", (code, signal) => {
      resolve({
        stdout,
        stderr: signal ? `${stderr}\nProcess terminated by ${signal}`.trim() : stderr,
        code: code ?? 1,
      });
    });
  });
}

// -----------------------------------------------------------------------------
// code_rewrite
// -----------------------------------------------------------------------------

const REWRITE_AGENTS = new Set(["coder", "swarm"]);
const PREVIEW_AGENTS = new Set(["researcher", "reviewer", "orchestrator", "explore"]);

const astgrepPath = Bun.which("ast-grep");

async function codeRewrite(
  input: {
    pattern: string;
    replacement: string;
    path?: string;
    lang?: "ts" | "js" | "py" | "go" | "rs" | "java" | "c" | "cpp";
    dryRun?: boolean;
  },
  ctx: {
    agent: string;
    progress: (u: Record<string, unknown>) => Promise<void>;
    signal?: AbortSignal;
  },
): Promise<string> {
  const { pattern, replacement, path = ".", lang, dryRun = true } = input;
  const agent = ctx.agent;

  if (!astgrepPath) {
    return "Error: ast-grep is not installed. Install with: cargo install ast-grep";
  }

  const canRewrite = REWRITE_AGENTS.has(agent);
  const canPreview = PREVIEW_AGENTS.has(agent) || canRewrite;

  if (!canPreview) {
    await ctx.progress({ title: `[DENIED] Rewrite by ${agent}` });
    return `Access Denied: Agent '${agent}' is not authorized for code rewrites.\nPreview agents: ${[...PREVIEW_AGENTS].join(", ")}\nRewrite agents: ${[...REWRITE_AGENTS].join(", ")}`;
  }

  const effectiveDryRun = !canRewrite || dryRun;

  if (!canRewrite && !dryRun) {
    await ctx.progress({
      title: `Forced preview for ${agent}`,
      metadata: { reason: "agent not authorized for writes" },
    });
  }

  const cmd = ["ast-grep", "--pattern", pattern, "--rewrite", replacement];
  if (lang) cmd.push("--lang", lang);
  cmd.push(path);

  if (effectiveDryRun) {
    const { stdout, stderr, code } = await spawnText(cmd, ctx.signal);
    if (code !== 0 && !stdout) return `ast-grep error: ${stderr}`;

    await ctx.progress({ title: `Preview rewrite by ${agent}` });

    const lines = stdout.trim().split("\n");
    const preview =
      lines.length > 50
        ? lines.slice(0, 50).join("\n") + `\n... (${lines.length - 50} more lines)`
        : stdout.trim() || "No matches found.";

    return `[PREVIEW MODE${!canRewrite ? " - agent restricted" : ""}]\n\nPattern: ${pattern}\nReplacement: ${replacement}\n\n${preview}`;
  }

  cmd.push("--update-all");
  const { stdout, stderr, code } = await spawnText(cmd, ctx.signal);
  if (code !== 0) return `ast-grep rewrite failed (exit ${code}): ${stderr}`;

  await ctx.progress({
    title: `Applied rewrite by ${agent}`,
    metadata: { pattern, replacement, path },
  });

  return `[CHANGES APPLIED]\n\nPattern: ${pattern}\nReplacement: ${replacement}\nPath: ${path}\n\n${stdout.trim() || "Rewrite completed."}`;
}

// -----------------------------------------------------------------------------
// degoog_search
// -----------------------------------------------------------------------------

const INSTANCE_URL = "https://degoog.nas.joncrangle.com";
const API_KEY = process.env.DEGOOG_API_KEY;
const SEARCH_TIMEOUT_MS = 10000;
const HEALTH_CACHE_TTL_AVAILABLE_MS = 60000;
const HEALTH_CACHE_TTL_UNAVAILABLE_MS = 15000;

let cachedAvailability: { isAvailable: boolean; timestamp: number } | null = null;

async function checkHealth(signal?: AbortSignal): Promise<boolean> {
  const now = Date.now();
  if (cachedAvailability) {
    const ttl = cachedAvailability.isAvailable
      ? HEALTH_CACHE_TTL_AVAILABLE_MS
      : HEALTH_CACHE_TTL_UNAVAILABLE_MS;
    if (now - cachedAvailability.timestamp < ttl) return cachedAvailability.isAvailable;
  }

  const controller = new AbortController();
  const onAbort = () => controller.abort();
  signal?.addEventListener("abort", onAbort, { once: true });
  const id = setTimeout(() => controller.abort(), 2000);

  try {
    const headers: Record<string, string> = {};
    if (API_KEY) headers["Authorization"] = `Bearer ${API_KEY}`;
    const response = await fetch(INSTANCE_URL, {
      method: "HEAD",
      headers,
      signal: controller.signal,
    });
    clearTimeout(id);
    const isAvailable = response.ok;
    cachedAvailability = { isAvailable, timestamp: now };
    return isAvailable;
  } catch {
    clearTimeout(id);
    cachedAvailability = { isAvailable: false, timestamp: now };
    return false;
  } finally {
    signal?.removeEventListener("abort", onAbort);
  }
}

const DEGOOG_CATEGORIES = [
  "general",
  "cargo",
  "packages",
  "it",
  "repos",
  "code",
  "scientific publications",
  "images",
  "videos",
  "news",
  "map",
  "music",
  "files",
  "social media",
] as const;

// Structural stand-in for the plugin context's websearch domain. Kept inline so
// this file does not depend on internal SDK types.
type WebsearchDomain = {
  query: (input: { query: string; providerID?: string }) => Promise<{
    data: {
      providerID: string;
      results: { url: string; title?: string; content?: string }[];
    };
  }>;
};

type DegoogSearchCtx = {
  signal?: AbortSignal;
  websearch: WebsearchDomain;
};

type DegoogResult = {
  title?: string;
  url?: string;
  content: string;
  engine?: string;
  score?: number;
};

// Runs the built-in websearch and reshapes it into the same JSON shape degoog
// returns, so the model's contract never changes. Never throws: failures come
// back as an `error` alongside an empty result set.
async function websearchFallback(
  query: string,
  limit: number,
  websearch: WebsearchDomain,
): Promise<{ results: DegoogResult[]; error?: string }> {
  try {
    const response = await websearch.query({ query });
    const results = response.data.results.map((r) => ({
      title: r.title,
      url: r.url,
      content: r.content ?? "",
      engine: `websearch:${response.data.providerID}`,
    }));
    if (results.length === 0) return { results, error: "websearch returned no results." };
    return { results: results.slice(0, limit) };
  } catch (error: unknown) {
    return { results: [], error: error instanceof Error ? error.message : String(error) };
  }
}

async function degoogSearch(
  input: {
    query: string;
    category?: (typeof DEGOOG_CATEGORIES)[number];
    time_range?: "day" | "week" | "month" | "year";
    limit?: number;
  },
  ctx: DegoogSearchCtx,
): Promise<string> {
  const { query, category = "general", time_range, limit = 10 } = input;

  if (!(await checkHealth(ctx.signal))) {
    const fallback = await websearchFallback(query, limit, ctx.websearch);
    if (fallback.error) {
      return JSON.stringify({
        error: `Degoog instance at ${INSTANCE_URL} is unreachable and the built-in websearch fallback failed: ${fallback.error}`,
      });
    }
    return JSON.stringify(fallback.results);
  }

  const url = new URL(`${INSTANCE_URL}/api/search`);
  url.searchParams.set("q", query);
  const type =
    category === "news" || category === "images" || category === "videos" ? category : "web";
  url.searchParams.set("type", type);
  if (time_range) url.searchParams.set("time", time_range);

  const controller = new AbortController();
  const onAbort = () => controller.abort();
  ctx.signal?.addEventListener("abort", onAbort, { once: true });
  const timeoutId = setTimeout(() => controller.abort(), SEARCH_TIMEOUT_MS);

  try {
    const headers: Record<string, string> = { Accept: "application/json" };
    if (API_KEY) headers["Authorization"] = `Bearer ${API_KEY}`;
    const response = await fetch(url.toString(), { headers, signal: controller.signal });
    clearTimeout(timeoutId);

    if (!response.ok) throw new Error(`Search failed with status ${response.status}`);

    const data = (await response.json()) as {
      results?: {
        title?: string;
        url?: string;
        snippet?: string;
        content?: string;
        source?: string;
        score?: number;
      }[];
    };
    const results = (data.results || [])
      .map((r) => ({
        title: r.title,
        url: r.url,
        content: r.snippet || r.content || "",
        engine: r.source,
        score: r.score,
      }))
      .slice(0, limit);

    if (results.length === 0) {
      const fallback = await websearchFallback(query, limit, ctx.websearch);
      if (fallback.error) {
        return JSON.stringify({
          error: `Degoog search for "${query}" returned no results and the built-in websearch fallback failed: ${fallback.error}`,
        });
      }
      return JSON.stringify(fallback.results);
    }

    return JSON.stringify(results);
  } catch (error: unknown) {
    clearTimeout(timeoutId);
    const errorMessage =
      error instanceof Error
        ? error.name === "AbortError"
          ? `Search timed out after ${SEARCH_TIMEOUT_MS / 1000} seconds.`
          : error.message
        : String(error);

    const fallback = await websearchFallback(query, limit, ctx.websearch);
    if (fallback.error) {
      return JSON.stringify({
        error: `Degoog search failed (${errorMessage}) and the built-in websearch fallback failed: ${fallback.error}`,
      });
    }
    return JSON.stringify(fallback.results);
  } finally {
    ctx.signal?.removeEventListener("abort", onAbort);
  }
}

// -----------------------------------------------------------------------------
// Registration
// -----------------------------------------------------------------------------

export default Plugin.define({
  id: "custom-tools",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "code_rewrite",
        description: astgrepPath
          ? "Rewrite code patterns using ast-grep. Uses AST-based matching for precise transformations. Only 'coder' and 'swarm' agents can apply changes; others get preview only."
          : "ast-grep CLI is not installed. Install it first to use this tool.",
        options: { permission: "code_rewrite", codemode: false },
        input: {
          type: "object",
          properties: {
            pattern: {
              type: "string",
              description:
                "The AST pattern to match (e.g., 'console.log($ARG)' or 'if ($COND) { $$$BODY }')",
            },
            replacement: {
              type: "string",
              description:
                "The replacement pattern using captured metavariables (e.g., 'logger.debug($ARG)')",
            },
            path: {
              type: "string",
              description: "File or directory to transform (default: current directory).",
            },
            lang: {
              type: "string",
              enum: ["ts", "js", "py", "go", "rs", "java", "c", "cpp"],
              description: "Target language for parsing (default: auto-detect).",
            },
            dryRun: {
              type: "boolean",
              description: "Preview changes without applying (default: true for safety).",
            },
          },
          required: ["pattern", "replacement"],
          additionalProperties: false,
        },
        async execute(input, context) {
          return {
            content: await codeRewrite(input as Parameters<typeof codeRewrite>[0], context),
          };
        },
      });

      editor.add({
        name: "degoog_search",
        description:
          "Search the web using a self-hosted search engine the user controls, so queries stay private and are not shared with a third party. This is the PREFERRED tool for all web search in this setup: use it INSTEAD of the built-in `websearch`. If the private instance is unreachable or returns nothing, it transparently falls back to the built-in `websearch` and returns results in the same shape, so never call `websearch` yourself.",
        options: { permission: "degoog_search", codemode: false },
        input: {
          type: "object",
          properties: {
            query: { type: "string", description: "The search query" },
            category: {
              type: "string",
              enum: [...DEGOOG_CATEGORIES],
              description: "The search category (default: general)",
            },
            time_range: {
              type: "string",
              enum: ["day", "week", "month", "year"],
              description: "Filter results by time range",
            },
            limit: {
              type: "number",
              description: "Maximum number of results to return (default: 10)",
            },
          },
          required: ["query"],
          additionalProperties: false,
        },
        async execute(input, context) {
          return {
            content: await degoogSearch(input as Parameters<typeof degoogSearch>[0], {
              signal: context.signal,
              websearch: ctx.websearch,
            }),
          };
        },
      });
    });
  },
});
