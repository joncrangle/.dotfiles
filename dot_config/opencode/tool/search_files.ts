import { tool } from "@opencode-ai/plugin";

export default tool({
  description:
    "Smart search tool. Finds code patterns using the fastest available utility (rg, grep, or findstr).",
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
      .describe("Limit to file types: 'ts', 'py', 'go', 'js', 'rs', etc. (ripgrep only)."),
  },
  async execute({ query, path = ".", caseSensitive = false, fileType }) {
    try {
      let cmd: string[];

      // 1. Try Ripgrep (Fastest, Cross-Platform)
      if (Bun.which("rg")) {
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
      // 2. Try Grep (Standard Unix/Mac/GitBash)
      else if (Bun.which("grep")) {
        cmd = ["grep", "-rn"];
        if (!caseSensitive) cmd.push("-i");
        cmd.push(query, path);
      }
      // 3. Fallback: Findstr (Windows Native)
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
