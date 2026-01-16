import { tool, ToolContext } from "@opencode-ai/plugin";

// =============================================================================
// CODE REWRITE TOOL - AST-based code transformations with access control
// =============================================================================

// Only these agents can perform destructive rewrites
const REWRITE_AGENTS = new Set(["coder", "swarm"]);

// Preview-only agents can view what would change but not apply
const PREVIEW_AGENTS = new Set(["researcher", "reviewer", "explore"]);

// Check if ast-grep (sg) is installed
const sgPath = Bun.which("sg");

export default tool({
  description: sgPath
    ? "Rewrite code patterns using ast-grep. Uses AST-based matching for precise transformations. Only 'coder' and 'swarm' agents can apply changes; others get preview only."
    : "ast-grep (sg) CLI is not installed. Install it first to use this tool.",
  args: {
    pattern: tool.schema
      .string()
      .describe(
        "The AST pattern to match (e.g., 'console.log($ARG)' or 'if ($COND) { $$$BODY }')"
      ),
    replacement: tool.schema
      .string()
      .describe(
        "The replacement pattern using captured metavariables (e.g., 'logger.debug($ARG)')"
      ),
    path: tool.schema
      .string()
      .optional()
      .describe("File or directory to transform (default: current directory)."),
    lang: tool.schema
      .enum(["ts", "js", "py", "go", "rs", "java", "c", "cpp"])
      .optional()
      .describe("Target language for parsing (default: auto-detect)."),
    dryRun: tool.schema
      .boolean()
      .optional()
      .describe("Preview changes without applying (default: true for safety)."),
  },
  async execute(
    { pattern, replacement, path = ".", lang, dryRun = true },
    ctx: ToolContext
  ) {
    const { agent } = ctx;

    // Guard: sg must be installed
    if (!sgPath) {
      return "Error: ast-grep (sg) is not installed. Install with: cargo install ast-grep";
    }

    // =========================================================================
    // ACCESS CONTROL: Determine agent permissions
    // =========================================================================
    const canRewrite = REWRITE_AGENTS.has(agent);
    const canPreview = PREVIEW_AGENTS.has(agent) || canRewrite;

    // Completely unauthorized agents
    if (!canPreview) {
      ctx.metadata({ title: `[DENIED] Rewrite by ${agent}` });
      return `Access Denied: Agent '${agent}' is not authorized for code rewrites.\nPreview agents: ${[...PREVIEW_AGENTS].join(", ")}\nRewrite agents: ${[...REWRITE_AGENTS].join(", ")}`;
    }

    // Force dry-run for preview-only agents
    const effectiveDryRun = !canRewrite || dryRun;

    if (!canRewrite && !dryRun) {
      ctx.metadata({
        title: `Forced preview for ${agent}`,
        metadata: { reason: "agent not authorized for writes" },
      });
    }

    try {
      // Build ast-grep command
      const cmd = ["sg", "--pattern", pattern, "--rewrite", replacement];

      if (lang) cmd.push("--lang", lang);
      cmd.push(path);

      if (effectiveDryRun) {
        // Preview mode: show what would change
        const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
        const output = await new Response(proc.stdout).text();
        const stderr = await new Response(proc.stderr).text();
        const exitCode = await proc.exited;

        if (exitCode !== 0 && !output) {
          return `ast-grep error: ${stderr}`;
        }

        ctx.metadata({ title: `Preview rewrite by ${agent}` });

        const lines = output.trim().split("\n");
        const preview =
          lines.length > 50
            ? lines.slice(0, 50).join("\n") +
              `\n... (${lines.length - 50} more lines)`
            : output.trim() || "No matches found.";

        return `[PREVIEW MODE${!canRewrite ? " - agent restricted" : ""}]\n\nPattern: ${pattern}\nReplacement: ${replacement}\n\n${preview}`;
      } else {
        // Apply mode: actually rewrite files
        cmd.push("--update-all");

        const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
        const output = await new Response(proc.stdout).text();
        const stderr = await new Response(proc.stderr).text();
        const exitCode = await proc.exited;

        if (exitCode !== 0) {
          return `ast-grep rewrite failed (exit ${exitCode}): ${stderr}`;
        }

        ctx.metadata({
          title: `Applied rewrite by ${agent}`,
          metadata: { pattern, replacement, path },
        });

        return `[CHANGES APPLIED]\n\nPattern: ${pattern}\nReplacement: ${replacement}\nPath: ${path}\n\n${output.trim() || "Rewrite completed."}`;
      }
    } catch (e) {
      return `Rewrite Error: ${e instanceof Error ? e.message : String(e)}`;
    }
  },
});
