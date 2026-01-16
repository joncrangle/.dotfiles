import { tool, ToolContext } from "@opencode-ai/plugin";

// =============================================================================
// AGENT ACCESS CONTROL CONFIGURATION
// =============================================================================

// Agents allowed to use AST pattern matching (expensive operation)
const AST_PATTERN_AGENTS = new Set(["coder", "researcher", "reviewer"]);

// Agents allowed to perform code rewrites (mutation operation)
const REWRITE_AGENTS = new Set(["coder"]);

// Agents restricted to read-only exploration (no mutation-oriented patterns)
const READ_ONLY_AGENTS = new Set(["explorer", "explore"]);

export default tool({
  description:
    "Smart search tool. Finds code patterns using the fastest available utility (sg, rg, grep, or findstr).",
  args: {
    query: tool.schema
      .string()
      .describe("The string or regex pattern to search for."),
    path: tool.schema
      .string()
      .optional()
      .describe("Directory or file to search (default: current directory)."),
    caseSensitive: tool.schema
      .boolean()
      .optional()
      .describe("Force case sensitivity (default: false)."),
    fileType: tool.schema
      .string()
      .optional()
      .describe("Limit to file types: 'ts', 'py', 'go', 'js', 'rs', etc."),
    rewrite: tool.schema
      .string()
      .optional()
      .describe("Replacement pattern for ast-grep rewrite (e.g., 'console.log($MSG)' -> '$MSG'). Only @coder agent is authorized."),
  },
  async execute({ query, path = ".", caseSensitive = false, fileType, rewrite }, ctx: ToolContext) {
    const { agent } = ctx;

    // Check if query looks like an AST pattern (contains meta-variables like $VAR)
    const isAstPattern = query.includes("$");

    // =========================================================================
    // ACCESS CONTROL: Restrict rewrites to @coder agent only
    // =========================================================================
    if (rewrite !== undefined && !REWRITE_AGENTS.has(agent)) {
      ctx.metadata({ title: `[DENIED] Rewrite by ${agent}` });
      return "Permission Denied: Only the @coder agent is authorized to perform code rewrites.";
    }

    // =========================================================================
    // ACCESS CONTROL: Restrict AST patterns to trusted agents
    // =========================================================================
    if (isAstPattern && !AST_PATTERN_AGENTS.has(agent)) {
      ctx.metadata({ title: `[DENIED] AST search by ${agent}` });
      return `Access Denied: Agent '${agent}' is not authorized to use AST patterns.\nAllowed agents: ${[...AST_PATTERN_AGENTS].join(", ")}`;
    }

    ctx.metadata({ title: `Search by ${agent}` });

    try {
      let cmd: string[];

      // =========================================================================
      // REWRITE MODE: Use ast-grep to perform structural code rewriting
      // =========================================================================
      if (rewrite !== undefined) {
        // Check if sg is available
        if (!Bun.which("sg")) {
          return "Rewrite Error: ast-grep (sg) is not installed or not in PATH. Install with: npm i -g @ast-grep/cli";
        }

        cmd = ["sg", "run", "--pattern", query, "--rewrite", rewrite, "--update-all"];
        if (fileType) cmd.push("-l", fileType);
        cmd.push(path);

        const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
        const stdout = await new Response(proc.stdout).text();
        const stderr = await new Response(proc.stderr).text();
        
        const output = (stdout + stderr).trim();
        const lines = output.split("\n");

        // Safety limit to save context tokens
        if (lines.length > 100) {
          return `${lines.slice(0, 100).join("\n")}\n... (and ${lines.length - 100} more lines)`;
        }

        return lines.length > 0 && lines[0] !== "" 
          ? output 
          : "Rewrite complete. No matches found or files already updated.";
      }

      // =========================================================================
      // SEARCH MODE: Use available search tools
      // =========================================================================

      // 1. Try ast-grep (Best for structured code search)
      // Use sg when: caseSensitive is true OR query is an AST pattern
      // sg doesn't have a simple case-insensitive flag, so fall back to rg for case-insensitive
      if (Bun.which("sg") && (caseSensitive || isAstPattern)) {
        cmd = ["sg", "-p", query];
        if (fileType) cmd.push("-l", fileType);
        cmd.push(path);
      }
      // 2. Try Ripgrep (Fastest, Cross-Platform)
      else if (Bun.which("rg")) {
        cmd = [
          "rg",
          "--line-number",
          "--column",
          "--no-heading",
          "--color=never",
        ];
        if (!caseSensitive) cmd.push("--ignore-case");
        if (fileType) cmd.push("--type", fileType);
        cmd.push(query, path);
      }
      // 3. Try Grep (Standard Unix/Mac/GitBash)
      else if (Bun.which("grep")) {
        cmd = ["grep", "-rn"];
        if (!caseSensitive) cmd.push("-i");
        cmd.push(query, path);
      }
      // 4. Fallback: Findstr (Windows Native)
      else {
        // findstr is limited but reliable on pure Windows
        // /N = print line numbers, /S = recursive, /I = case insensitive
        cmd = ["findstr", "/N", "/S"];
        if (!caseSensitive) cmd.push("/I");
        cmd.push(query, path === "." ? "*.*" : path);
      }

      const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
      const output = await new Response(proc.stdout).text();

      const lines = output.trim().split("\n");

      // Safety limit to save context tokens
      if (lines.length > 100) {
        return `${lines.slice(0, 100).join("\n")}\n... (and ${lines.length - 100} more matches)`;
      }

      return lines.length > 0 && lines[0] !== "" ? output : "No matches found.";
    } catch (e) {
      return `Search Error: ${e instanceof Error ? e.message : String(e)}`;
    }
  },
});
