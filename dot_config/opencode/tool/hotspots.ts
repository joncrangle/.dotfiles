import { tool } from "@opencode-ai/plugin";

export default tool({
  description:
    "Analyzes the git history to identify 'hotspots'—files that are frequently changed. Use this to understand the core logic or unstable parts of the codebase.",
  args: {
    limit: tool.schema
      .number()
      .optional()
      .describe("The number of top files to return (default: 20)."),
    since: tool.schema
      .string()
      .optional()
      .describe(
        "Timeframe to analyze (e.g., '1 month ago', '2 weeks ago'). Default is entire history.",
      ),
    author: tool.schema
      .string()
      .optional()
      .describe("Filter commits by author name or email."),
  },
  async execute({ limit = 20, since, author }) {
    try {
      const args = ["git", "log", "--format=format:", "--name-only"];
      if (since) args.push(`--since=${since}`);
      if (author) args.push(`--author=${author}`);

      const proc = Bun.spawn(args, { stdout: "pipe" });
      const text = await new Response(proc.stdout).text();

      const counts: Record<string, number> = {};

      for (const line of text.split("\n")) {
        const file = line.trim();
        if (!file || file.includes("node_modules") || file.endsWith(".lock"))
          continue;
        counts[file] = (counts[file] || 0) + 1;
      }

      const sorted = Object.entries(counts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, limit);

      if (sorted.length === 0) return "No file history found.";

      return sorted
        .map(([file, count]) => `${String(count).padEnd(4)} ${file}`)
        .join("\n");
    } catch (e) {
      return `Error analyzing hotspots: ${e instanceof Error ? e.message : String(e)}`;
    }
  },
});
