import { $ } from "bun";
import { tool } from "@opencode-ai/plugin";

// Check if btca is installed at module load time (cached for performance)
const btcaPath = Bun.which("btca");

export default tool({
  description: btcaPath
    ? "Query btca (better context tool CLI) to ask questions about resources or list available resources. Use 'ask' to query a specific resource with a question, 'list' to see all available resources, or 'add' to register a new resource from a git URL or local path."
    : "btca CLI is not installed. Install btca first to use this tool.",
  args: {
    action: tool.schema
      .enum(["ask", "list", "add"])
      .describe(
        "Action to perform: 'ask' to query a resource, 'list' to show available resources.",
      ),
    resource: tool.schema
      .string()
      .optional()
      .describe("Resource name to query (required for 'ask' action)."),
    question: tool.schema
      .string()
      .optional()
      .describe("Question to ask the resource (required for 'ask' action)."),
    url: tool.schema
      .string()
      .optional()
      .describe(
        "Git repository URL or local path to add as a resource (required for 'add' action).",
      ),
  },
  async execute({ action, resource, question, url }) {
    // Guard: btca must be installed
    if (!btcaPath) {
      return "Error: btca is not installed or not in PATH. Install it first to use this tool.";
    }

    try {
      if (action === "list") {
        // List available btca resources
        const result = await $`btca config resources list`.quiet().nothrow();
        const output = result.text();
        const stderr = result.stderr.toString();

        if (result.exitCode !== 0) {
          return `btca list failed (exit ${result.exitCode}): ${stderr || output}`;
        }

        return output.trim() || "No resources found.";
      }

      if (action === "ask") {
        // Validate required args for 'ask'
        if (!resource) {
          return "Error: 'resource' is required for the 'ask' action. Use 'list' to see available resources.";
        }
        if (!question) {
          return "Error: 'question' is required for the 'ask' action.";
        }

        // Query the resource with the question
        const result =
          await $`btca ask --resource ${resource} --question ${question}`
            .quiet()
            .nothrow();
        const output = result.text();
        const stderr = result.stderr.toString();

        if (result.exitCode !== 0) {
          return `btca ask failed (exit ${result.exitCode}): ${stderr || output}`;
        }

        // Truncate very long responses to save context tokens
        const lines = output.trim().split("\n");
        if (lines.length > 200) {
          return `${lines.slice(0, 200).join("\n")}\n... (truncated, ${lines.length - 200} more lines)`;
        }

        return output.trim() || "No response from btca.";
      }

      if (action === "add") {
        // Validate required arg for 'add'
        if (!url) {
          return "Error: 'url' is required for the 'add' action. Provide a git repository URL or local path.";
        }

        // Add a new resource
        const result = await $`btca config resources add ${url}`
          .quiet()
          .nothrow();
        const output = result.text();
        const stderr = result.stderr.toString();

        if (result.exitCode !== 0) {
          return `btca add failed (exit ${result.exitCode}): ${stderr || output}`;
        }

        return output.trim() || `Resource added: ${url}`;
      }

      return `Unknown action: ${action}. Use 'ask', 'list', or 'add'.`;
    } catch (e) {
      return `btca Error: ${e instanceof Error ? e.message : String(e)}`;
    }
  },
});
