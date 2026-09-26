import { Plugin } from "@opencode/plugin"
import { spawn, execFile } from "node:child_process"
import { promisify } from "node:util"

const execFileAsync = promisify(execFile)

// =============================================================================
// Custom tools ported from the V1 `tool()` API to V2 tool transforms.
//
// Each tool declares `options.permission` so agents can still target it by name
// (e.g. `{action: "search_files", resource: "*", effect: "deny"}`).
// =============================================================================

function spawnText(
  cmd: string[],
  signal?: AbortSignal,
): Promise<{ stdout: string; stderr: string; code: number }> {
  return new Promise((resolve) => {
    const child = spawn(cmd[0]!, cmd.slice(1), { signal })
    let stdout = ""
    let stderr = ""
    child.stdout?.on("data", (d) => (stdout += d))
    child.stderr?.on("data", (d) => (stderr += d))
    child.on("error", (e) => resolve({ stdout, stderr: String(e), code: 1 }))
    child.on("close", (code) => resolve({ stdout, stderr, code: code ?? 0 }))
  })
}

// -----------------------------------------------------------------------------
// code_rewrite
// -----------------------------------------------------------------------------

const REWRITE_AGENTS = new Set(["coder", "swarm"])
const PREVIEW_AGENTS = new Set(["researcher", "reviewer", "explore"])

const astgrepPath = Bun.which("ast-grep")

async function codeRewrite(
  input: {
    pattern: string
    replacement: string
    path?: string
    lang?: "ts" | "js" | "py" | "go" | "rs" | "java" | "c" | "cpp"
    dryRun?: boolean
  },
  ctx: {
    agent: string
    progress: (u: Record<string, unknown>) => Promise<void>
    signal?: AbortSignal
  },
): Promise<string> {
  const { pattern, replacement, path = ".", lang, dryRun = true } = input
  const agent = ctx.agent

  if (!astgrepPath) {
    return "Error: ast-grep is not installed. Install with: cargo install ast-grep"
  }

  const canRewrite = REWRITE_AGENTS.has(agent)
  const canPreview = PREVIEW_AGENTS.has(agent) || canRewrite

  if (!canPreview) {
    await ctx.progress({ title: `[DENIED] Rewrite by ${agent}` })
    return `Access Denied: Agent '${agent}' is not authorized for code rewrites.\nPreview agents: ${[...PREVIEW_AGENTS].join(", ")}\nRewrite agents: ${[...REWRITE_AGENTS].join(", ")}`
  }

  const effectiveDryRun = !canRewrite || dryRun

  if (!canRewrite && !dryRun) {
    await ctx.progress({
      title: `Forced preview for ${agent}`,
      metadata: { reason: "agent not authorized for writes" },
    })
  }

  const cmd = ["ast-grep", "--pattern", pattern, "--rewrite", replacement]
  if (lang) cmd.push("--lang", lang)
  cmd.push(path)

  if (effectiveDryRun) {
    const { stdout, stderr, code } = await spawnText(cmd, ctx.signal)
    if (code !== 0 && !stdout) return `ast-grep error: ${stderr}`

    await ctx.progress({ title: `Preview rewrite by ${agent}` })

    const lines = stdout.trim().split("\n")
    const preview =
      lines.length > 50
        ? lines.slice(0, 50).join("\n") + `\n... (${lines.length - 50} more lines)`
        : stdout.trim() || "No matches found."

    return `[PREVIEW MODE${!canRewrite ? " - agent restricted" : ""}]\n\nPattern: ${pattern}\nReplacement: ${replacement}\n\n${preview}`
  }

  cmd.push("--update-all")
  const { stdout, stderr, code } = await spawnText(cmd, ctx.signal)
  if (code !== 0) return `ast-grep rewrite failed (exit ${code}): ${stderr}`

  await ctx.progress({
    title: `Applied rewrite by ${agent}`,
    metadata: { pattern, replacement, path },
  })

  return `[CHANGES APPLIED]\n\nPattern: ${pattern}\nReplacement: ${replacement}\nPath: ${path}\n\n${stdout.trim() || "Rewrite completed."}`
}

// -----------------------------------------------------------------------------
// search_files
// -----------------------------------------------------------------------------

const AST_PATTERN_AGENTS = new Set(["coder", "researcher", "reviewer"])
const SEARCH_REWRITE_AGENTS = new Set(["coder"])

async function searchFiles(
  input: {
    query: string
    path?: string
    caseSensitive?: boolean
    fileType?: string
    rewrite?: string
  },
  ctx: { agent: string; progress: (u: Record<string, unknown>) => Promise<void>; signal?: AbortSignal },
): Promise<string> {
  const { query, path = ".", caseSensitive = false, fileType, rewrite } = input
  const agent = ctx.agent
  const isAstPattern = query.includes("$")

  if (rewrite !== undefined && !SEARCH_REWRITE_AGENTS.has(agent)) {
    await ctx.progress({ title: `[DENIED] Rewrite by ${agent}` })
    return "Permission Denied: Only the @coder agent is authorized to perform code rewrites."
  }

  if (isAstPattern && !AST_PATTERN_AGENTS.has(agent)) {
    await ctx.progress({ title: `[DENIED] AST search by ${agent}` })
    return `Access Denied: Agent '${agent}' is not authorized to use AST patterns.\nAllowed agents: ${[...AST_PATTERN_AGENTS].join(", ")}`
  }

  await ctx.progress({ title: `Search by ${agent}` })

  let cmd: string[]

  if (rewrite !== undefined) {
    if (!Bun.which("sg")) {
      return "Rewrite Error: ast-grep (sg) is not installed or not in PATH. Install with: npm i -g @ast-grep/cli"
    }
    cmd = ["sg", "run", "--pattern", query, "--rewrite", rewrite, "--update-all"]
    if (fileType) cmd.push("-l", fileType)
    cmd.push(path)
  } else if (Bun.which("sg") && (caseSensitive || isAstPattern || fileType)) {
    cmd = ["sg", "-p", query]
    if (fileType) cmd.push("-l", fileType)
    cmd.push(path)
  } else if (Bun.which("rg")) {
    cmd = ["rg", "--line-number", "--column", "--no-heading", "--color=never"]
    if (!caseSensitive) cmd.push("--ignore-case")
    if (fileType) cmd.push("--type", fileType)
    cmd.push(query, path)
  } else if (Bun.which("grep")) {
    cmd = ["grep", "-rn"]
    if (!caseSensitive) cmd.push("-i")
    cmd.push(query, path)
  } else {
    cmd = ["findstr", "/N", "/S"]
    if (!caseSensitive) cmd.push("/I")
    cmd.push(query, path === "." ? "*.*" : path)
  }

  const { stdout, stderr } = await spawnText(cmd, ctx.signal)
  const output = (stdout + stderr).trim()
  const lines = output.split("\n")

  if (lines.length > 100) {
    return `${lines.slice(0, 100).join("\n")}\n... (and ${lines.length - 100} more lines)`
  }

  if (rewrite === undefined) {
    return lines.length > 0 && lines[0] !== "" ? output : "No matches found."
  }
  return lines.length > 0 && lines[0] !== "" ? output : "Rewrite complete. No matches found or files already updated."
}

// -----------------------------------------------------------------------------
// list_files
// -----------------------------------------------------------------------------

const RESTRICTED_PATHS = [".env", "secrets", ".ssh", "credentials", ".aws", "private"]
const ELEVATED_AGENTS = new Set(["coder", "git", "swarm"])

function isRestrictedPath(path: string): boolean {
  const normalized = path.toLowerCase()
  return RESTRICTED_PATHS.some((p) => normalized.includes(p) || normalized.endsWith(p))
}

async function listFiles(
  input: { path?: string; style?: "simple" | "long" | "all" | "tree" },
  ctx: { agent: string; progress: (u: Record<string, unknown>) => Promise<void> },
): Promise<string> {
  const { path = ".", style = "simple" } = input
  const agent = ctx.agent

  if (isRestrictedPath(path) && !ELEVATED_AGENTS.has(agent)) {
    await ctx.progress({ title: `[DENIED] List ${path} by ${agent}` })
    return `Access Denied: Agent '${agent}' cannot list restricted path '${path}'.\nElevated agents: ${[...ELEVATED_AGENTS].join(", ")}`
  }

  await ctx.progress({ title: `List ${path} by ${agent}` })

  const run = async (argv: string[]) => {
    try {
      return await execFileAsync(argv[0]!, argv.slice(1), { maxBuffer: 10 * 1024 * 1024 })
    } catch (e: any) {
      return { stdout: "", stderr: e?.stderr?.toString() ?? e?.message ?? "error" }
    }
  }

  if (Bun.which("eza")) {
    const flags: string[] = []
    if (style === "long") flags.push("-l", "--git")
    if (style === "all") flags.push("-l", "-a", "--git")
    if (style === "tree") flags.push("-T", "--level=2")
    const r = await run(["eza", ...flags, "--color=never", "--group-directories-first", path])
    return r.stdout || r.stderr
  }

  if (Bun.which("ls")) {
    if (style === "tree") {
      if (Bun.which("tree")) {
        const r = await run(["tree", "-L", "2", path])
        return r.stdout || r.stderr
      }
      const r = await run(["ls", "-R", path])
      return r.stdout || r.stderr
    }
    const flags: string[] = []
    if (style === "long") flags.push("-lh")
    if (style === "all") flags.push("-lah")
    const r = await run(["ls", ...flags, path])
    return r.stdout || r.stderr
  }

  if (style === "tree") {
    const r = await run(["tree", "/F", "/A", path])
    return r.stdout || r.stderr
  }
  const flags: string[] = []
  if (style === "simple") flags.push("/B")
  if (style === "all") flags.push("/A")
  const r = await run(["dir", ...flags, path])
  return r.stdout || r.stderr
}

// -----------------------------------------------------------------------------
// degoog_search
// -----------------------------------------------------------------------------

const INSTANCE_URL = "https://degoog.nas.joncrangle.com"
const API_KEY = process.env.DEGOOG_API_KEY
const SEARCH_TIMEOUT_MS = 10000
const HEALTH_CACHE_TTL_AVAILABLE_MS = 60000
const HEALTH_CACHE_TTL_UNAVAILABLE_MS = 15000

let cachedAvailability: { isAvailable: boolean; timestamp: number } | null = null

async function checkHealth(signal?: AbortSignal): Promise<boolean> {
  const now = Date.now()
  if (cachedAvailability) {
    const ttl = cachedAvailability.isAvailable
      ? HEALTH_CACHE_TTL_AVAILABLE_MS
      : HEALTH_CACHE_TTL_UNAVAILABLE_MS
    if (now - cachedAvailability.timestamp < ttl) return cachedAvailability.isAvailable
  }

  const controller = new AbortController()
  const onAbort = () => controller.abort()
  signal?.addEventListener("abort", onAbort, { once: true })
  const id = setTimeout(() => controller.abort(), 2000)

  try {
    const headers: Record<string, string> = {}
    if (API_KEY) headers["Authorization"] = `Bearer ${API_KEY}`
    const response = await fetch(INSTANCE_URL, { method: "HEAD", headers, signal: controller.signal })
    clearTimeout(id)
    const isAvailable = response.ok
    cachedAvailability = { isAvailable, timestamp: now }
    return isAvailable
  } catch {
    clearTimeout(id)
    cachedAvailability = { isAvailable: false, timestamp: now }
    return false
  } finally {
    signal?.removeEventListener("abort", onAbort)
  }
}

const DEGOOG_CATEGORIES = [
  "general", "cargo", "packages", "it", "repos", "code",
  "scientific publications", "images", "videos", "news",
  "map", "music", "files", "social media",
] as const

async function degoogSearch(
  input: {
    query: string
    category?: (typeof DEGOOG_CATEGORIES)[number]
    time_range?: "day" | "week" | "month" | "year"
    limit?: number
  },
  ctx: { progress: (u: Record<string, unknown>) => Promise<void>; signal?: AbortSignal },
): Promise<string> {
  const { query, category = "general", time_range, limit = 10 } = input

  await ctx.progress({ title: `Degoog Search: ${query}` })

  if (!(await checkHealth(ctx.signal))) {
    return JSON.stringify({ error: `Degoog instance at ${INSTANCE_URL} is unreachable.` })
  }

  const url = new URL(`${INSTANCE_URL}/api/search`)
  url.searchParams.set("q", query)
  const type = category === "news" || category === "images" || category === "videos" ? category : "web"
  url.searchParams.set("type", type)
  if (time_range) url.searchParams.set("time", time_range)

  const controller = new AbortController()
  const onAbort = () => controller.abort()
  ctx.signal?.addEventListener("abort", onAbort, { once: true })
  const timeoutId = setTimeout(() => controller.abort(), SEARCH_TIMEOUT_MS)

  try {
    const headers: Record<string, string> = { Accept: "application/json" }
    if (API_KEY) headers["Authorization"] = `Bearer ${API_KEY}`
    const response = await fetch(url.toString(), { headers, signal: controller.signal })
    clearTimeout(timeoutId)

    if (!response.ok) throw new Error(`Search failed with status ${response.status}`)

    const data = (await response.json()) as {
      results?: { title?: string; url?: string; snippet?: string; content?: string; source?: string; score?: number }[]
    }
    const results = (data.results || [])
      .map((r) => ({
        title: r.title,
        url: r.url,
        content: r.snippet || r.content || "",
        engine: r.source,
        score: r.score,
      }))
      .slice(0, limit)

    return JSON.stringify(results)
  } catch (error: unknown) {
    clearTimeout(timeoutId)
    const errorMessage =
      error instanceof Error
        ? error.name === "AbortError"
          ? `Search timed out after ${SEARCH_TIMEOUT_MS / 1000} seconds.`
          : error.message
        : String(error)
    return JSON.stringify({ error: errorMessage })
  } finally {
    ctx.signal?.removeEventListener("abort", onAbort)
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
        options: { permission: "code_rewrite" },
        input: {
          type: "object",
          properties: {
            pattern: { type: "string", description: "The AST pattern to match (e.g., 'console.log($ARG)' or 'if ($COND) { $$$BODY }')" },
            replacement: { type: "string", description: "The replacement pattern using captured metavariables (e.g., 'logger.debug($ARG)')" },
            path: { type: "string", description: "File or directory to transform (default: current directory)." },
            lang: { type: "string", enum: ["ts", "js", "py", "go", "rs", "java", "c", "cpp"], description: "Target language for parsing (default: auto-detect)." },
            dryRun: { type: "boolean", description: "Preview changes without applying (default: true for safety)." },
          },
          required: ["pattern", "replacement"],
          additionalProperties: false,
        },
        async execute(input, context) {
          return { content: await codeRewrite(input as Parameters<typeof codeRewrite>[0], context) }
        },
      })

      editor.add({
        name: "search_files",
        description:
          "Smart search tool. Finds code patterns using the fastest available utility (sg, rg, grep, or findstr).",
        options: { permission: "search_files" },
        input: {
          type: "object",
          properties: {
            query: { type: "string", description: "The string or regex pattern to search for." },
            path: { type: "string", description: "Directory or file to search (default: current directory)." },
            caseSensitive: { type: "boolean", description: "Force case sensitivity (default: false)." },
            fileType: { type: "string", description: "Limit to file types: 'ts', 'py', 'go', 'js', 'rs', etc." },
            rewrite: {
              type: "string",
              description: "Replacement pattern for ast-grep rewrite (e.g., 'console.log($MSG)' -> '$MSG'). Only @coder agent is authorized.",
            },
          },
          required: ["query"],
          additionalProperties: false,
        },
        async execute(input, context) {
          return { content: await searchFiles(input as Parameters<typeof searchFiles>[0], context) }
        },
      })

      editor.add({
        name: "list_files",
        description:
          "List files and directories. Uses 'eza' (modern ls) if available, falling back to 'ls' or Windows 'dir'.",
        options: { permission: "list_files" },
        input: {
          type: "object",
          properties: {
            path: { type: "string", description: "The directory to list (default: current directory)." },
            style: {
              type: "string",
              enum: ["simple", "long", "all", "tree"],
              description: "Output style: 'simple' (names only), 'long' (permissions/size), 'all' (includes hidden files), 'tree' (hierarchical view). Default: 'simple'.",
            },
          },
          additionalProperties: false,
        },
        async execute(input, context) {
          return { content: await listFiles(input as Parameters<typeof listFiles>[0], context) }
        },
      })

      editor.add({
        name: "degoog_search",
        description:
          "Search the web using Degoog search aggregator with enhanced filtering and timeout control.",
        options: { permission: "degoog_search" },
        input: {
          type: "object",
          properties: {
            query: { type: "string", description: "The search query" },
            category: { type: "string", enum: [...DEGOOG_CATEGORIES], description: "The search category (default: general)" },
            time_range: { type: "string", enum: ["day", "week", "month", "year"], description: "Filter results by time range" },
            limit: { type: "number", description: "Maximum number of results to return (default: 10)" },
          },
          required: ["query"],
          additionalProperties: false,
        },
        async execute(input, context) {
          return { content: await degoogSearch(input as Parameters<typeof degoogSearch>[0], context) }
        },
      })
    })
  },
})
