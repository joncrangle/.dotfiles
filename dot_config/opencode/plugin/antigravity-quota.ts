import type { Plugin } from "@opencode-ai/plugin";
import { tool } from "@opencode-ai/plugin";
import { homedir } from "os";
import { join } from "path";

const EXCLUDED_PATTERNS = [
  "chat",
  "rev19",
  "gemini-3-pro-image",
  "gemini-2.5",
  "tab-flash",
];

/**
 * Normalize a string for pattern matching by replacing all non-alphanumeric
 * characters with hyphens and lowercasing.
 */
function normalizeForMatch(str: string): string {
  return str.toLowerCase().replace(/[^a-z0-9]/g, "-");
}

// Pre-normalize excluded patterns once for efficient matching
const NORMALIZED_EXCLUDED_PATTERNS = EXCLUDED_PATTERNS.map(normalizeForMatch);

const isWindows = process.platform === "win32";
const configDir = isWindows
  ? join(homedir(), "AppData", "Roaming", "opencode")
  : join(homedir(), ".config", "opencode");
const accountsFile = join(configDir, "antigravity-accounts.json");

const OAUTH_CLIENT_ID =
  "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
const OAUTH_CLIENT_SECRET = "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";
const CLOUDCODE_BASE_URL = "https://cloudcode-pa.googleapis.com";

const QUOTA_CHECK_INTERVAL = 4; // Check quota every N user turns
const DEBUG = true; // When true, append error messages to chat if fetchQuota fails

// Per-session state tracking
interface SessionState {
  turnCount: number;
  lastQuotaDisplay: number;
}
const sessionStates = new Map<string, SessionState>();

function getSessionState(sessionID: string): SessionState {
  let state = sessionStates.get(sessionID);
  if (!state) {
    state = { turnCount: 0, lastQuotaDisplay: 0 };
    sessionStates.set(sessionID, state);
  }
  return state;
}

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
  resetTime?: string;
}

interface ModelInfo {
  quotaInfo?: QuotaInfo;
}

interface FetchModelsResponse {
  models?: Record<string, ModelInfo>;
}

function formatRelativeTime(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  
  if (diffMs <= 0) return "now";
  
  const diffMins = Math.round(diffMs / 60000);
  const hours = Math.floor(diffMins / 60);
  const mins = diffMins % 60;
  
  if (hours > 0) {
    return `${hours}h ${mins}m`;
  }
  return `${mins}m`;
}

function getQuotaStatus(percent: number): string {
  if (percent <= 0) return "🔴"; // Depleted
  if (percent < 20) return "🔴"; // Critical
  if (percent < 50) return "🟡"; // Warning
  return "🟢"; // Normal
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
    throw new Error(
      `Account file not found at: ${accountsFile}. Run 'antigravity auth' to authenticate.`,
    );
  }

  let config: AccountsConfig;
  try {
    const text = await file.text();
    config = JSON.parse(text);
  } catch (parseErr) {
    throw new Error(
      `Invalid JSON in account file: ${accountsFile}. ${parseErr instanceof Error ? parseErr.message : String(parseErr)}`,
    );
  }

  if (!config.accounts || !Array.isArray(config.accounts)) {
    throw new Error(
      `Malformed account file: missing 'accounts' array in ${accountsFile}`,
    );
  }

  const account = config.accounts[config.activeIndex ?? 0];

  if (!account) {
    throw new Error(
      `No active account at index ${config.activeIndex ?? 0}. Available accounts: ${config.accounts.length}`,
    );
  }

  if (!account.refreshToken) {
    throw new Error(
      `Active account is missing refreshToken. Re-authenticate with 'antigravity auth'.`,
    );
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

  lines.push(`Antigravity Quota`);
  lines.push("─".repeat(50));
  lines.push("");

  // Find summary Claude/Gemini for header line
  let claudePct: number | null = null;
  let geminiPct: number | null = null;

  // Collect all models with quota
  const modelsWithQuota: Array<{ name: string; percent: number; reset?: string }> = [];

  for (const [name, info] of Object.entries(data.models)) {
    // Skip models matching excluded patterns (normalize separators for matching)
    const normalizedName = normalizeForMatch(name);
    if (NORMALIZED_EXCLUDED_PATTERNS.some((p) => normalizedName.includes(p))) {
      continue;
    }

    const fraction = info.quotaInfo?.remainingFraction;
    if (fraction === undefined || fraction === null) continue;

    const percent = Math.round(fraction * 100);
    modelsWithQuota.push({ name, percent, reset: info.quotaInfo?.resetTime });

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

  // Sort by percentage (lowest first) to highlight critically low models
  modelsWithQuota.sort((a, b) => a.percent - b.percent);

  // Summary line
  const claudeStr = claudePct !== null ? `${getQuotaStatus(claudePct)} ${claudePct}%` : "--%";
  const geminiStr = geminiPct !== null ? `${getQuotaStatus(geminiPct)} ${geminiPct}%` : "--%";
  lines.push(`Claude: ${claudeStr} • Gemini: ${geminiStr}`);
  lines.push("");

  // Detailed breakdown with visual bars
  lines.push("Model Details:");
  for (const { name, percent, reset } of modelsWithQuota) {
    const filled = Math.floor(percent / 10);
    const empty = 10 - filled;
    const bar = "█".repeat(filled) + "░".repeat(empty);
    const status = getQuotaStatus(percent);
    
    let details = `    ${status} ${bar} ${percent}%`;
    if (reset) {
      details += ` • Resets in ${formatRelativeTime(reset)}`;
    }
    
    lines.push(`  ${name}`);
    lines.push(details);
  }

  return "```\n" + lines.join("\n") + "\n```";
}

const plugin: Plugin = async (_ctx) => {
  return {
    hooks: {
      // Track user messages and append quota on intervals
      "chat.message": async (
        input: { sessionID: string },
        output: { message: { role: string; content: string } },
      ) => {
        const sessionState = getSessionState(input.sessionID);

        // Count user turns
        if (output.message.role === "user") {
          sessionState.turnCount++;
        }

        // After assistant responds, display quota on interval-based turns
        if (
          output.message.role === "assistant" &&
          sessionState.turnCount > 0 &&
          sessionState.turnCount % QUOTA_CHECK_INTERVAL === 0 &&
          sessionState.lastQuotaDisplay !== sessionState.turnCount
        ) {
          try {
            const quota = await fetchQuota();
            output.message.content += `\n\n---\n\n${quota}`;
            sessionState.lastQuotaDisplay = sessionState.turnCount;
          } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            if (DEBUG) {
              output.message.content += `\n\n---\n\n⚠️ Quota display failed: ${msg}`;
            }
            sessionState.lastQuotaDisplay = sessionState.turnCount;
          }
        }
      },
    },

    // Register /quota command via config hook
    async config(config) {
      config.command = config.command || {};
      config.command.quota = {
        template: `Call the quota tool and display the output verbatim in a code block. 
Output ONLY the code block. 
Do not include any commentary, explanations, reasoning, or tags like <commentary>.`,
        description: "Check Antigravity AI quota",
      };
    },

    // Register quota tool
    tool: {
      quota: tool({
        description:
          "Check Antigravity AI quota remaining - returns detailed breakdown of all models with visual progress bars. IMPORTANT: Display the output EXACTLY as returned, do not reformat. Do not add any commentary, explanations, or tags.",
        args: {},
        async execute(_args, _context) {
          try {
            const result = await fetchQuota();
            return result;
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
