import { connection } from "next/server";
import { Pool } from "pg";

/**
 * How the app is doing, for deploy.sh, the Deploy workflow and an uptime monitor:
 *
 *   200 {"database":"ok","worker":"ok","build":"<the commit's full SHA>"}
 *   503 {"database":"down","worker":"unknown","build":"<the commit's full SHA>"}
 *
 * - `database`: whether the database answers. 503 when it doesn't.
 * - `worker`: whether the background worker beat lately: "ok", "late", "none" before its first
 *   beat, "unknown" without a database to ask. A monitor that looks for `"worker":"ok"` hears about
 *   a stopped worker too. Without a worker, drop it.
 * - `build`: the commit the image was built from (BUILD_COMMIT, Dockerfile). A deploy waits until
 *   it's the build it started, so the container before can't pass for the new one.
 *
 * Public, as whoever asks has no account: the answer says no more than up or down and which build
 * answers. What went wrong is logged, never returned.
 */
export async function GET() {
  // About this moment, so never prerendered or cached.
  await connection();
  const database = (await databaseAnswers()) ? "ok" : "down";
  const worker = database === "ok" ? await workerBeat() : "unknown";
  return Response.json(
    { database, worker, build: process.env.BUILD_COMMIT || null },
    { status: database === "ok" ? 200 : 503, headers: { "cache-control": "no-store" } },
  );
}

// What the check asks. Better than `SELECT 1`: a table the first migration creates, so a database
// whose migrations never ran counts as down too, e.g. "SELECT 1 FROM users LIMIT 1".
const DATABASE_PROBE = "SELECT 1";

// The worker upserts its row every 30 seconds:
//   INSERT INTO heartbeat (name, at, build) VALUES ('worker', now(), $1)
//   ON CONFLICT (name) DO UPDATE SET at = excluded.at, build = excluded.build
// More than two minutes without one is late: a few missed beats, not one slow one.
const WORKER_PROBE =
  "SELECT now() - at <= interval '2 minutes' AS fresh FROM heartbeat WHERE name = 'worker'";

/** Whether the database answers. */
async function databaseAnswers(): Promise<boolean> {
  try {
    await pool().query(DATABASE_PROBE);
    return true;
  } catch (error) {
    console.error("Health check: the database didn't answer.", error);
    return false;
  }
}

/** Whether the worker beat lately. */
async function workerBeat(): Promise<"ok" | "late" | "none" | "unknown"> {
  try {
    const { rows } = await pool().query<{ fresh: boolean }>(WORKER_PROBE);
    const [row] = rows;
    if (!row) return "none";
    return row.fresh ? "ok" : "late";
  } catch (error) {
    console.error("Health check: couldn't read the worker's heartbeat.", error);
    return "unknown";
  }
}

// A small pool of its own with short timeouts, so a hung database fails the check in seconds rather
// than hanging the deploy's poll. Made on the first request (the build has no database) and kept on
// globalThis, so development's reloads reuse it. An app with a database client of its own can ask
// through that instead, with the same timeouts.
const holder = globalThis as typeof globalThis & { healthPool?: Pool };

function pool(): Pool {
  if (!holder.healthPool) {
    holder.healthPool = new Pool({
      connectionString: process.env.DATABASE_URL,
      max: 2,
      connectionTimeoutMillis: 3_000,
      idleTimeoutMillis: 30_000,
      statement_timeout: 3_000,
    });
    // An idle connection the database drops (a restart, say) is reported here; unheard, it would
    // end the process.
    holder.healthPool.on("error", (error) => console.error("Health check: a database connection failed.", error));
  }
  return holder.healthPool;
}
