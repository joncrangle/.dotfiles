import { tool } from "@opencode-ai/plugin";

function validateCommit(msg: string): string | null {
  if (msg.length > 72) {
    return `Error: Commit message is too long (${msg.length} chars). Please keep the subject under 72 characters.`;
  }

  const conventionalRegex =
    /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9-]+\))?: .+/;

  if (!conventionalRegex.test(msg)) {
    return `Error: Message must follow Conventional Commits format.\nFormat: <type>(<scope>): <subject>\nExamples:\n- "feat: add user login"\n- "fix(ui): align button"\n- "chore: update dependencies"`;
  }

  return null;
}

export default tool({
  description:
    "A safe wrapper for common Git operations. Handles status checks, staging, committing, and pushing.",
  args: {
    action: tool.schema
      .enum([
        "status",
        "add",
        "commit",
        "push",
        "log",
        "diff",
        "branch",
        "reset",
      ])
      .describe("The git operation to perform."),
    target: tool.schema
      .string()
      .optional()
      .describe(
        "For 'add', the file path (or '.' for all). For 'diff', the file or branch.",
      ),
    message: tool.schema
      .string()
      .optional()
      .describe("The commit message. Required for 'commit'."),
  },
  async execute({ action, target, message }) {
    try {
      switch (action) {
        case "status":
          return await Bun.$`git status -s`.text();

        case "add":
          if (!target) return "Error: target required for 'add'";
          await Bun.$`git add ${target}`; // Bun automatically escapes 'target'
          return `✓ Staged: ${target}`;

        case "commit": {
          if (!message) return "Error: message required";

          const err = validateCommit(message);
          if (err) return err;

          await Bun.$`git commit -m ${message}`;
          return `✓ Committed: "${message}"`;
        }

        case "push": {
          // Get current branch name safely
          const branch = (await Bun.$`git branch --show-current`.text()).trim();
          await Bun.$`git push origin ${branch}`;
          return `✓ Pushed to origin/${branch}`;
        }

        case "log":
          return await Bun.$`git log --oneline -n 10`.text();

        case "diff":
          // If target is missing, default to HEAD
          return await Bun.$`git diff ${target || "HEAD"}`.text();

        case "branch":
          return await Bun.$`git branch -a`.text();

        case "reset":
          // Soft unstage only - safe operation
          if (!target)
            return "Error: target required for 'reset' (file path to unstage)";
          await Bun.$`git reset HEAD ${target}`;
          return `✓ Unstaged: ${target}`;

        default:
          return `Error: Unknown action '${action}'`;
      }
    } catch (error: any) {
      return `Git Error (Exit ${error.exitCode}): ${error.stderr.toString().trim()}`;
    }
  },
});
