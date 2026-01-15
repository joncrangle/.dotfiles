import type { Plugin } from "@opencode-ai/plugin";
import { tool } from "@opencode-ai/plugin";
import { homedir } from "os";
import { join } from "path";

const configDir = join(homedir(), ".config", "opencode");
const accountsFile = join(configDir, "antigravity-accounts.json");

const OAUTH_CLIENT_ID =
  "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
const OAUTH_CLIENT_SECRET = "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";
const CLOUDCODE_BASE_URL = "https://cloudcode-pa.googleapis.com";

const QUOTA_CHECK_INTERVAL = 4; // Check quota every N user turns

interface AntigravityAccount {
  refreshToken: string;
  projectId: string;
  email?: string;
}

interface AccountsConfig {
  version: number;
  accounts: AntigravityAccount[];
  activeIndex: number;
}

interface QuotaInfo {
  remainingFraction?: number;
}

interface ModelInfo {
  quotaInfo?: QuotaInfo;
}

interface FetchModelsResponse {
  models?: Record<string, ModelInfo>;
}

async function getAccessToken(refreshToken: string): Promise<string> {
  const cleanToken = refreshToken.split("|")[0];

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: OAUTH_CLIENT_ID,
      client_secret: OAUTH_CLIENT_SECRET,
      refresh_token: cleanToken,
      grant_type: "refresh_token",
    }),
  });

  if (!response.ok) {
    throw new Error(`Auth failed: ${response.status}`);
  }

  const data = (await response.json()) as { access_token: string };
  return data.access_token;
}

async function fetchQuota(): Promise<string> {
  // Read config
  const file = Bun.file(accountsFile);
  if (!(await file.exists())) {
    return "❌ No Antigravity account found";
  }

  const config: AccountsConfig = JSON.parse(await file.text());
  const account = config.accounts[config.activeIndex ?? 0];

  if (!account) {
    return "❌ No active account";
  }

  // Get token
  const accessToken = await getAccessToken(account.refreshToken);

  // Fetch models
  const response = await fetch(
    `${CLOUDCODE_BASE_URL}/v1internal:fetchAvailableModels`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "User-Agent": "antigravity",
      },
      body: JSON.stringify({ project: account.projectId }),
    },
  );

  if (!response.ok) {
    return `❌ API error: ${response.status}`;
  }

  const data = (await response.json()) as FetchModelsResponse;

  if (!data.models) {
    return "❌ No quota data";
  }

  // Build output
  const lines: string[] = [];

  // Header with email if available
  if (account.email) {
    lines.push(`Antigravity Quota (${account.email})`);
  } else {
    lines.push(`Antigravity Quota`);
  }
  lines.push("─".repeat(50));
  lines.push("");

  // Find summary Claude/Gemini for header line
  let claudePct: number | null = null;
  let geminiPct: number | null = null;

  // Collect all models with quota
  const modelsWithQuota: Array<{ name: string; percent: number }> = [];

  for (const [name, info] of Object.entries(data.models)) {
    const fraction = info.quotaInfo?.remainingFraction;
    if (fraction === undefined || fraction === null) continue;

    const percent = Math.round(fraction * 100);
    modelsWithQuota.push({ name, percent });

    // Track summary values
    if (name.toLowerCase().includes("claude") && claudePct === null) {
      claudePct = percent;
    } else if (
      name.toLowerCase().includes("gemini") &&
      name.includes("flash") &&
      geminiPct === null
    ) {
      geminiPct = percent;
    }
  }

  // Summary line
  const claudeStr = claudePct !== null ? `${claudePct}%` : "--%";
  const geminiStr = geminiPct !== null ? `${geminiPct}%` : "--%";
  lines.push(`Claude: ${claudeStr} • Gemini: ${geminiStr}`);
  lines.push("");

  // Detailed breakdown with visual bars
  lines.push("Model Details:");
  for (const { name, percent } of modelsWithQuota) {
    const filled = Math.floor(percent / 10);
    const empty = 10 - filled;
    const bar = "█".repeat(filled) + "░".repeat(empty);
    lines.push(`  ${name}`);
    lines.push(`    ${bar} ${percent}% remaining`);
  }

  return "```\n" + lines.join("\n") + "\n```";
}

const plugin: Plugin = async (_ctx) => {
  let turnCount = 0;

  return {
    hooks: {
      // Track user messages and trigger quota display every 4 turns
      "chat.message": async (
        _input: { sessionID: string },
        output: { message: { role: string } },
      ) => {
        // Only count user messages
        if (output.message.role === "user") {
          turnCount++;
        }
      },

      // Inject quota into system prompt every 4 turns
      "experimental.chat.system.transform": async (
        _input: { sessionID: string },
        output: { system: string[] },
      ) => {
        // Every 4 turns, inject quota info into system context
        if (turnCount > 0 && turnCount % QUOTA_CHECK_INTERVAL === 0) {
          try {
            const quota = await fetchQuota();
            output.system.push(`[Quota Update - Turn ${turnCount}]\n${quota}`);
          } catch {
            // Silently fail - don't interrupt user
          }
        }
      },
    },

    // Register /quota command via config hook
    async config(config) {
      config.command = config.command || {};
      config.command.quota = {
        template: `Call the quota tool and display the EXACT output verbatim.
Do NOT summarize, reformat, or convert to tables.
The output is already formatted - just show it as-is in a code block.`,
        description: "Check Antigravity AI quota",
      };
    },

    // Register quota tool that can be called by AI
    tool: {
      quota: tool({
        description:
          "Check Antigravity AI quota remaining - returns detailed breakdown of all models with visual progress bars. IMPORTANT: Display the output EXACTLY as returned, do not reformat.",
        args: {},
        async execute(_args, _context) {
          try {
            const result = await fetchQuota();
            return `DISPLAY THIS EXACTLY AS-IS (do not summarize or reformat):\n\n${result}`;
          } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return `❌ Error: ${msg}`;
          }
        },
      }),
    },
  };
};

export default plugin;
