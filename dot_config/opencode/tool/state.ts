import { tool } from "@opencode-ai/plugin";
import { Database } from "bun:sqlite";
import { mkdir } from "node:fs/promises";

// =============================================================================
// STATE TOOL - Share data between parent and child sessions
// =============================================================================

await mkdir(".opencode", { recursive: true });
const db = new Database(".opencode/state.db", { create: true });

db.run("PRAGMA journal_mode = WAL");
db.run("PRAGMA synchronous = NORMAL");
db.run("PRAGMA busy_timeout = 5000;");

db.run(`
  CREATE TABLE IF NOT EXISTS state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at INTEGER,
    agent TEXT
  )
`);

const stmt = {
  get: db.query("SELECT value FROM state WHERE key = $key"),
  set: db.query(
    "INSERT OR REPLACE INTO state (key, value, updated_at, agent) VALUES ($key, $val, $time, $agent)",
  ),
  del: db.query("DELETE FROM state WHERE key = $key"),
  list: db.query("SELECT key, agent FROM state ORDER BY updated_at DESC"),
  clear: db.query("DELETE FROM state"),
};

export default tool({
  description:
    "A persistent key-value store to share data, context, or project requirements across different chat sessions or agents.",
  args: {
    action: tool.schema
      .enum(["get", "set", "del", "list", "clear"])
      .describe("The operation to perform on the state store."),
    key: tool.schema
      .string()
      .optional()
      .describe("The unique key for the data. Required for get, set, and del."),
    value: tool.schema
      .any()
      .optional()
      .describe(
        "The data to store. Supports strings, numbers, arrays, or JSON objects. Required for 'set'.",
      ),
  },
  async execute({ action, key, value }, { agent }) {
    try {
      switch (action) {
        case "set":
          if (!key || value === undefined)
            return "Error: 'key' and 'value' are required for 'set'.";
          stmt.set.run({
            $key: key,
            $val: JSON.stringify(value),
            $time: Date.now(),
            $agent: agent || "unknown",
          });
          return `✓ Data stored under key: ${key}`;

        case "get":
          if (!key) return "Error: 'key' is required for 'get'.";
          const row = stmt.get.get({ $key: key }) as { value: string } | null;
          return row ? JSON.parse(row.value) : "null (key not found)";

        case "list":
          const rows = stmt.list.all() as { key: string; agent: string }[];
          return rows.length
            ? rows.map((r) => `- ${r.key} (set by ${r.agent})`).join("\n")
            : "The state store is currently empty.";

        case "del":
          if (!key) return "Error: 'key' is required for 'del'.";
          stmt.del.run({ $key: key });
          return `✓ Key '${key}' has been deleted.`;

        case "clear":
          const result = stmt.clear.run();
          return `✓ State store cleared (${result.changes} entries removed).`;
      }
    } catch (e) {
      return `State Tool Error: ${e instanceof Error ? e.message : String(e)}`;
    }
  },
});
