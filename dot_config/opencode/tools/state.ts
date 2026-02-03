import { tool } from "@opencode-ai/plugin";
import { Database } from "bun:sqlite";
import { mkdir } from "node:fs/promises";

// =============================================================================
// AGENT STATE DB
// Persistent, agent-only key-value store with TTL + metadata
// =============================================================================

const MAX_VALUE_BYTES = 1_048_576; // 1MB (byte-accurate)

// -----------------------------------------------------------------------------
// Lazy singletons (no top-level await)
// -----------------------------------------------------------------------------

let _db: Database | null = null;
let _stmts: {
  get: ReturnType<Database["query"]>;
  set: ReturnType<Database["query"]>;
  del: ReturnType<Database["query"]>;
  list: ReturnType<Database["query"]>;
  clear: ReturnType<Database["query"]>;
  count: ReturnType<Database["query"]>;
  touch: ReturnType<Database["query"]>;
  meta: ReturnType<Database["query"]>;
} | null = null;

// -----------------------------------------------------------------------------
// DB Initialization
// -----------------------------------------------------------------------------

async function getDb(): Promise<Database> {
  if (_db) return _db;

  await mkdir(".opencode", { recursive: true });
  _db = new Database(".opencode/state.db", { create: true });

  _db.run("PRAGMA journal_mode = WAL");
  _db.run("PRAGMA synchronous = NORMAL");
  _db.run("PRAGMA busy_timeout = 5000");
  _db.run("PRAGMA foreign_keys = ON");

  _db.run(`
    CREATE TABLE IF NOT EXISTS state (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      type TEXT NOT NULL,
      agent TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      accessed_at INTEGER NOT NULL,
      expires_at INTEGER
    ) WITHOUT ROWID
  `);

  _db.run(
    "CREATE INDEX IF NOT EXISTS idx_state_updated ON state(updated_at DESC)",
  );
  _db.run("CREATE INDEX IF NOT EXISTS idx_state_agent ON state(agent)");
  _db.run("CREATE INDEX IF NOT EXISTS idx_state_expires ON state(expires_at)");

  return _db;
}

// -----------------------------------------------------------------------------
// Prepared Statements
// -----------------------------------------------------------------------------

async function getStmts() {
  if (_stmts) return _stmts;

  const db = await getDb();

  _stmts = {
    get: db.query(`
      SELECT value, type
      FROM state
      WHERE key = $key
        AND (expires_at IS NULL OR expires_at > $now)
    `),

    set: db.query(`
      INSERT INTO state (
        key, value, type, agent,
        created_at, updated_at, accessed_at, expires_at
      )
      VALUES (
        $key, $value, $type, $agent,
        $now, $now, $now, $expires
      )
      ON CONFLICT(key) DO UPDATE SET
        value = excluded.value,
        type = excluded.type,
        agent = excluded.agent,
        updated_at = excluded.updated_at,
        accessed_at = excluded.accessed_at,
        expires_at = excluded.expires_at
    `),

    del: db.query("DELETE FROM state WHERE key = $key RETURNING key"),

    list: db.query(`
      SELECT key, type, agent, updated_at, expires_at
      FROM state
      WHERE expires_at IS NULL OR expires_at > $now
      ORDER BY updated_at DESC
    `),

    clear: db.query("DELETE FROM state"),

    count: db.query("SELECT COUNT(*) as count FROM state"),

    touch: db.query(`
      UPDATE state
      SET accessed_at = $now
      WHERE key = $key
    `),

    meta: db.query(`
      SELECT key, type, agent, created_at, updated_at, accessed_at, expires_at
      FROM state
      WHERE key = $key
    `),
  };

  return _stmts;
}

// -----------------------------------------------------------------------------
// Utilities
// -----------------------------------------------------------------------------

function detectType(value: unknown): string {
  if (value === null) return "null";
  if (Array.isArray(value)) return "array";
  return typeof value;
}

function serializeValue(value: unknown): string | null {
  try {
    return JSON.stringify(value);
  } catch {
    return null;
  }
}

function byteLength(str: string): number {
  return new TextEncoder().encode(str).length;
}

// -----------------------------------------------------------------------------
// Tool Definition
// -----------------------------------------------------------------------------

export default tool({
  description:
    "Agent-only persistent state database with TTL, metadata, and size limits.",

  args: {
    action: tool.schema.enum(["get", "set", "del", "list", "clear", "meta"]),
    key: tool.schema.string().optional(),
    value: tool.schema.any().optional(),
    ttl: tool.schema
      .number()
      .optional()
      .describe("Time-to-live in milliseconds (set only)."),
  },

  async execute({ action, key, value, ttl }, context) {
    const agent = context?.agent || "unknown";
    const now = Date.now();

    try {
      const stmts = await getStmts();

      switch (action) {
        // -------------------------------------------------------------------
        case "set": {
          if (!key) {
            return JSON.stringify({ error: "key is required" });
          }
          if (value === undefined) {
            return JSON.stringify({ error: "value is required" });
          }

          const serialized = serializeValue(value);
          if (serialized === null) {
            return JSON.stringify({
              error: "Value is not JSON-serializable",
            });
          }

          const size = byteLength(serialized);
          if (size > MAX_VALUE_BYTES) {
            return JSON.stringify({
              error: `Value exceeds ${MAX_VALUE_BYTES} bytes`,
              size,
            });
          }

          stmts.set.run({
            $key: key,
            $value: serialized,
            $type: detectType(value),
            $agent: agent,
            $now: now,
            $expires: ttl ? now + ttl : null,
          });

          return JSON.stringify({
            success: true,
            key,
            size,
            ttl: ttl ?? null,
          });
        }

        // -------------------------------------------------------------------
        case "get": {
          if (!key) {
            return JSON.stringify({ error: "key is required" });
          }

          const row = stmts.get.get({
            $key: key,
            $now: now,
          }) as { value: string; type: string } | null;

          if (!row) {
            return JSON.stringify({ found: false });
          }

          stmts.touch.run({ $key: key, $now: now });

          return JSON.stringify({
            found: true,
            value: JSON.parse(row.value),
            type: row.type,
          });
        }

        // -------------------------------------------------------------------
        case "meta": {
          if (!key) {
            return JSON.stringify({ error: "key is required" });
          }

          const row = stmts.meta.get({ $key: key });
          return JSON.stringify(row ?? { found: false });
        }

        // -------------------------------------------------------------------
        case "list": {
          const rows = stmts.list.all({ $now: now });
          return JSON.stringify(rows);
        }

        // -------------------------------------------------------------------
        case "del": {
          if (!key) {
            return JSON.stringify({ error: "key is required" });
          }

          const deleted = stmts.del.all({ $key: key });
          return JSON.stringify({
            success: true,
            key,
            deleted: deleted.length > 0,
          });
        }

        // -------------------------------------------------------------------
        case "clear": {
          const countRow = stmts.count.get() as { count: number };
          stmts.clear.run();

          return JSON.stringify({
            success: true,
            cleared: countRow?.count ?? 0,
          });
        }

        // -------------------------------------------------------------------
        default:
          return JSON.stringify({ error: `Unknown action: ${action}` });
      }
    } catch (err) {
      return JSON.stringify({
        error: err instanceof Error ? err.message : String(err),
      });
    }
  },
});
