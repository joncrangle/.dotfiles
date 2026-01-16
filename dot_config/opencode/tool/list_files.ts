import { tool, ToolContext } from "@opencode-ai/plugin";

// =============================================================================
// AGENT ACCESS CONTROL CONFIGURATION
// =============================================================================

// Paths that require elevated access (only certain agents can list)
const RESTRICTED_PATHS = [
  ".env",
  "secrets",
  ".ssh",
  "credentials",
  ".aws",
  "private",
];

// Agents allowed to access restricted paths
const ELEVATED_AGENTS = new Set(["coder", "git", "swarm"]);

// Log file for audit trail
const AUDIT_LOG = ".opencode/list_audit.log";

async function logAccess(agent: string, path: string, style: string, allowed: boolean) {
  const entry = JSON.stringify({
    timestamp: new Date().toISOString(),
    agent,
    path,
    style,
    allowed,
  });
  try {
    const file = Bun.file(AUDIT_LOG);
    const existing = await file.exists() ? await file.text() : "";
    await Bun.write(AUDIT_LOG, existing + entry + "\n");
  } catch {
    // Ignore logging failures silently
  }
}

function isRestrictedPath(path: string): boolean {
  const normalized = path.toLowerCase();
  return RESTRICTED_PATHS.some(
    (p) => normalized.includes(p) || normalized.endsWith(p)
  );
}

export default tool({
  description:
    "List files and directories. Uses 'eza' (modern ls) if available, falling back to 'ls' or Windows 'dir'.",
  args: {
    path: tool.schema
      .string()
      .optional()
      .describe("The directory to list (default: current directory)."),
    style: tool.schema
      .enum(["simple", "long", "all", "tree"])
      .optional()
      .describe(
        "Output style: 'simple' (names only), 'long' (permissions/size), 'all' (includes hidden files), 'tree' (hierarchical view). Default: 'simple'.",
      ),
  },
  async execute({ path = ".", style = "simple" }, ctx: ToolContext) {
    const { agent } = ctx;

    // =========================================================================
    // ACCESS CONTROL: Restrict sensitive directories
    // =========================================================================
    if (isRestrictedPath(path) && !ELEVATED_AGENTS.has(agent)) {
      await logAccess(agent, path, style, false);
      ctx.metadata({ title: `[DENIED] List ${path} by ${agent}` });
      return `Access Denied: Agent '${agent}' cannot list restricted path '${path}'.\nElevated agents: ${[...ELEVATED_AGENTS].join(", ")}`;
    }

    // Log successful access
    await logAccess(agent, path, style, true);
    ctx.metadata({ title: `List ${path} by ${agent}` });

    try {
      // 1. Try Eza
      if (Bun.which("eza")) {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            break;
          case "long":
            flags.push("-l", "--git");
            break;
          case "all":
            flags.push("-l", "-a", "--git");
            break;
          case "tree":
            flags.push("-T", "--level=2");
            break;
        }

        return await Bun.$`eza ${flags} --color=never --group-directories-first ${path}`
          .nothrow()
          .text();
      }

      // 2. Try Standard 'ls' (Linux/Mac/GitBash)
      else if (Bun.which("ls")) {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            break;
          case "long":
            flags.push("-lh");
            break;
          case "all":
            flags.push("-lah");
            break;
          case "tree":
            // Fallback: Check if native 'tree' command exists
            if (Bun.which("tree")) {
              return await Bun.$`tree -L 2 ${path}`.nothrow().text();
            }
            // If no tree, force a recursive ls limited to depth?
            // Better to just return a standard recursive listing or warn.
            return await Bun.$`ls -R ${path}`.nothrow().text();
        }

        return await Bun.$`ls ${flags} ${path}`.nothrow().text();
      }

      // 3. Try Windows 'dir' (CMD/PowerShell)
      else {
        const flags: string[] = [];

        switch (style) {
          case "simple":
            flags.push("/B");
            break;
          case "long":
            break;
          case "all":
            flags.push("/A");
            break;
          case "tree":
            return await Bun.$`tree /F /A ${path}`.nothrow().text();
        }

        // Note: Windows path separator handling is automatic in Bun.$
        return await Bun.$`dir ${flags} ${path}`.nothrow().text();
      }
    } catch (e: any) {
      return `List Error: ${e.stderr ? e.stderr.toString() : e.message}`;
    }
  },
});
