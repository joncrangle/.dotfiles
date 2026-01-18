import { tool } from "@opencode-ai/plugin";
import { Database } from "bun:sqlite";
import { mkdir } from "node:fs/promises";

// =============================================================================
// STATE TOOL - Share data between parent and child sessions
// =============================================================================

const MAX_VALUE_SIZE = 1_048_576; // 1MB limit

// Lazy singleton pattern - no top-level await
let _db: Database | null = null;
let _stmts: {
  get: ReturnType<Database["query"]>;
  set: ReturnType<Database["query"]>;
  del: ReturnType<Database["query"]>;
  list: ReturnType<Database["query"]>;
  clear: ReturnType<Database["query"]>;
  count: ReturnType<Database["query"]>;
} | null = null;

async function getDb(): Promise<Database> {
  if (_db) return _db;

  await mkdir(".opencode", { recursive: true });
  _db = new Database(".opencode/state.db", { create: true });

  _db.run("PRAGMA journal_mode = WAL");
  _db.run("PRAGMA synchronous = NORMAL");
  _db.run("PRAGMA busy_timeout = 5000");

  _db.run(`
    CREATE TABLE IF NOT EXISTS state (
      key TEXT PRIMARY KEY,
      value TEXT,
      type TEXT,
      updated_at INTEGER,
      agent TEXT
    )
  `);

  // Add index for updated_at queries
  _db.run("CREATE INDEX IF NOT EXISTS idx_updated_at ON state(updated_at)");

  return _db;
}

async function getStmts() {
  if (_stmts) return _stmts;

  const db = await getDb();

  _stmts = {
    get: db.query("SELECT value, type FROM state WHERE key = $key"),
    set: db.query(
      "INSERT OR REPLACE INTO state (key, value, type, updated_at, agent) VALUES ($key, $val, $type, $time, $agent)",
    ),
    del: db.query("DELETE FROM state WHERE key = $key RETURNING key"),
    list: db.query(
      "SELECT key, agent, updated_at FROM state ORDER BY updated_at DESC",
    ),
    clear: db.query("DELETE FROM state"),
    count: db.query("SELECT COUNT(*) as count FROM state"),
  };

  return _stmts;
}

function detectType(value: unknown): string {
  if (value === null) return "null";
  if (Array.isArray(value)) return "array";
  return typeof value;
}

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
  async execute({ action, key, value }, context) {
    const agent = context?.agent || "unknown";

    try {
      const stmts = await getStmts();

      switch (action) {
        case "set": {
          if (!key) {
            return JSON.stringify({ error: "'key' is required for 'set'" });
          }
          if (value === undefined) {
            return JSON.stringify({ error: "'value' is required for 'set'" });
          }

          // Always serialize to JSON
          const serialized = JSON.stringify(value);

          // Check size limit
          if (serialized.length > MAX_VALUE_SIZE) {
            return JSON.stringify({
              error: `Value exceeds maximum size of ${MAX_VALUE_SIZE} characters (got ${serialized.length})`,
            });
          }

          const valueType = detectType(value);

          stmts.set.run({
            $key: key,
            $val: serialized,
            $type: valueType,
            $time: Date.now(),
            $agent: agent,
          });

          return JSON.stringify({ success: true, key });
        }

        case "get": {
          if (!key) {
            return JSON.stringify({ error: "'key' is required for 'get'" });
          }

          const row = stmts.get.get({ $key: key }) as {
            value: string;
            type: string;
          } | null;

          if (!row) {
            return JSON.stringify({ found: false });
          }

          // Return raw JSON value (already serialized)
          return row.value;
        }

        case "list": {
          const rows = stmts.list.all() as {
            key: string;
            agent: string;
            updated_at: number;
          }[];

          return JSON.stringify(
            rows.map((r) => ({
              key: r.key,
              agent: r.agent,
              updated_at: r.updated_at,
            })),
          );
        }

        case "del": {
          if (!key) {
            return JSON.stringify({ error: "'key' is required for 'del'" });
          }

          const deleted = stmts.del.all({ $key: key }) as { key: string }[];

          return JSON.stringify({
            success: true,
            key,
            deleted: deleted.length > 0,
          });
        }

        case "clear": {
          // Get count before clearing
          const countRow = stmts.count.get() as { count: number };
          const count = countRow?.count ?? 0;

          stmts.clear.run();

          return JSON.stringify({ success: true, count });
        }

        default:
          return JSON.stringify({ error: `Unknown action: ${action}` });
      }
    } catch (e) {
      return JSON.stringify({
        error: e instanceof Error ? e.message : String(e),
      });
    }
  },
});
