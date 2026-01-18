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

function normalizeForMatch(str: string): string {
  return str.toLowerCase().replace(/[^a-z0-9]/g, "-");
}

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

const QUOTA_CHECK_INTERVAL = 4;
const DEBUG = false;
const QUOTA_MESSAGE_MARKER = "Antigravity Quota";

let quotaFetchInProgress = false;
let lastNotificationTimestamp = 0;
const NOTIFICATION_THROTTLE_MS = 60000; // 1 minute throttle

// Cache for session info to avoid redundant API calls
const sessionCache = new Map<
  string,
  { parentID?: string; isSubAgent: boolean }
>();

async function getSessionInfo(client: any, sessionId: string) {
  if (sessionCache.has(sessionId)) {
    return sessionCache.get(sessionId)!;
  }

  try {
    const result = await client.session.get({ path: { id: sessionId } });
    const info = {
      parentID: result.data?.parentID,
      isSubAgent: !!result.data?.parentID,
    };
    sessionCache.set(sessionId, info);
    return info;
  } catch (err) {
    return { isSubAgent: false };
  }
}

async function getPrimarySessionId(
  client: any,
  sessionId: string,
): Promise<string> {
  const info = await getSessionInfo(client, sessionId);
  if (info.parentID) {
    return getPrimarySessionId(client, info.parentID);
  }
  return sessionId;
}

async function sendNotification(
  client: any,
  sessionId: string,
  content: string,
  originalMessage: any,
) {
  try {
    await client.session.prompt({
      path: { id: sessionId },
      body: {
        noReply: true,
        agent: originalMessage.info.agent,
        model: originalMessage.info.model,
        variant: originalMessage.info.variant,
        parts: [
          {
            type: "text",
            text: content + "\n",
            ignored: true,
          },
        ],
      },
    });
  } catch (err) {
    if (DEBUG) {
      console.error("Failed to send quota notification:", err);
    }
  }
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
  if (percent <= 5) return "🔴";
  if (percent < 20) return "🟠";
  if (percent < 50) return "🟡";
  return "🟢";
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
  const file = Bun.file(accountsFile);
  if (!(await file.exists())) {
    throw new Error(
      `Account file not found at: ${accountsFile}. Run 'antigravity auth' to authenticate.`,
    );
  }

  let config: AccountsConfig;
  try {
    config = (await file.json()) as AccountsConfig;
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

  const accessToken = await getAccessToken(account.refreshToken);

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

  const lines: string[] = [];

  lines.push(QUOTA_MESSAGE_MARKER);
  lines.push("─".repeat(50));
  lines.push("");

  let claudePct: number | null = null;
  let geminiPct: number | null = null;

  const modelsWithQuota: Array<{
    name: string;
    percent: number | null;
    reset?: string;
  }> = [];

  for (const [name, info] of Object.entries(data.models)) {
    const normalizedName = normalizeForMatch(name);
    if (NORMALIZED_EXCLUDED_PATTERNS.some((p) => normalizedName.includes(p))) {
      continue;
    }

    const fraction = info.quotaInfo?.remainingFraction;
    let percent: number | null = null;

    if (fraction !== undefined && fraction !== null) {
      percent = Math.round(fraction * 100);
    } else if (info.quotaInfo?.resetTime) {
      percent = 0;
    } else {
      continue;
    }

    modelsWithQuota.push({ name, percent, reset: info.quotaInfo?.resetTime });

    if (
      name.toLowerCase().includes("claude") &&
      claudePct === null &&
      percent !== null
    ) {
      claudePct = percent;
    } else if (
      name.toLowerCase().includes("gemini") &&
      name.includes("flash") &&
      geminiPct === null &&
      percent !== null
    ) {
      geminiPct = percent;
    }
  }

  modelsWithQuota.sort((a, b) => {
    const pA = a.percent ?? 101;
    const pB = b.percent ?? 101;
    return pA - pB;
  });

  const claudeStr =
    claudePct !== null ? `${getQuotaStatus(claudePct)} ${claudePct}%` : "--%";
  const geminiStr =
    geminiPct !== null ? `${getQuotaStatus(geminiPct)} ${geminiPct}%` : "--%";
  lines.push(`Claude: ${claudeStr} • Gemini: ${geminiStr}`);
  lines.push("");

  lines.push("Model Details:");
  for (const { name, percent, reset } of modelsWithQuota) {
    let details: string;

    if (percent !== null) {
      const filled = Math.floor(percent / 10);
      const empty = 10 - filled;
      const bar = "█".repeat(filled) + "░".repeat(empty);
      const status = getQuotaStatus(percent);
      details = `    ${status} ${bar} ${percent}%`;
    } else {
      details = `    ⚪ ░░░░░░░░░░ --%`;
    }

    if (reset) {
      details += ` • Resets in ${formatRelativeTime(reset)}`;
    }

    lines.push(`  ${name}`);
    lines.push(details);
  }

  return lines.join("\n");
}

const plugin: Plugin = async (ctx) => {
  return {
    "experimental.chat.messages.transform": async (
      _input: {},
      output: {
        messages: Array<{
          info: {
            role: string;
            sessionID: string;
            agent?: string;
            model?: { providerID: string; modelID: string };
            variant?: string;
          };
          parts: Array<{ type: string; text?: string }>;
        }>;
      },
    ) => {
      const assistantTurns = output.messages.filter(
        (msg) =>
          msg.info.role === "assistant" &&
          !msg.parts.some((p) => p.text?.includes(QUOTA_MESSAGE_MARKER)),
      ).length;

      const lastMessage = output.messages[output.messages.length - 1];
      if (!lastMessage) return;

      const sessionID = lastMessage.info.sessionID;
      const alreadyHasQuota = lastMessage.parts.some((p) =>
        p.text?.includes(QUOTA_MESSAGE_MARKER),
      );

      if (
        assistantTurns > 0 &&
        assistantTurns % QUOTA_CHECK_INTERVAL === 0 &&
        !alreadyHasQuota
      ) {
        // Throttle notifications to avoid spamming the primary view
        const now = Date.now();
        if (now - lastNotificationTimestamp < NOTIFICATION_THROTTLE_MS) {
          return;
        }

        // Guard against concurrent fetches during re-renders
        if (quotaFetchInProgress) return;
        quotaFetchInProgress = true;

        try {
          const quotaContent = await fetchQuota();
          const primarySessionId = await getPrimarySessionId(
            ctx.client,
            sessionID,
          );

          await sendNotification(
            ctx.client,
            primarySessionId,
            quotaContent,
            lastMessage,
          );
          lastNotificationTimestamp = Date.now();
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          if (DEBUG) {
            const primarySessionId = await getPrimarySessionId(
              ctx.client,
              sessionID,
            );
            await sendNotification(
              ctx.client,
              primarySessionId,
              `⚠️ Quota display failed: ${msg}`,
              lastMessage,
            );
          }
        } finally {
          quotaFetchInProgress = false;
        }
      }
    },

    async config(config: Record<string, unknown>) {
      const cmd = (config.command || {}) as Record<string, unknown>;
      config.command = cmd;
      cmd.quota = {
        template: `Call the quota tool and display the output verbatim in a code block. 
Output ONLY the code block. 
Do not include any commentary, explanations, reasoning, or tags like <commentary>.`,
        description: "Check Antigravity AI quota",
      };
    },

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
