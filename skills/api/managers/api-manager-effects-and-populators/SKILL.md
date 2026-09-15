---
name: api-manager-effects-and-populators
description: >-
  The two composition layers underneath the declarative manager pattern —
  deferred side-effects (realtime socket emit, audit log, CDN purge, all
  run independently via Promise.allSettled) and populators (batched,
  composable read-time enrichment, including the data-driven polymorphic
  feature table for share/like/comment/view-style cross-cutting features).
  Use when adding a new realtime event, wiring audit logging for a model,
  adding a derived/aggregate field to a manager's populated shape, or
  adding a new polymorphic feature (e.g. reactions) that several models
  should be able to opt into with one line each. Companion to
  api-manager-base and api-manager-declarative-config.
metadata:
  type: practice
  category: architecture
---

## Rule

### Effects — deferred, declarative side-effects

An `Effect` is a zero-argument async closure — nothing happens until it's
actually called. This lets a mutation *assemble* its list of side-effects
declaratively and fire them all together, typically right after a DB
transaction commits:

```ts
// src/lib/managers/base/effects.ts
export type Effect = () => Promise<void>;

export function socket<T extends WebSocketEmittableEvent>(
  event: T,
  opts: {
    /** A value, or a thunk — a thunk defers expensive follow-up work until the effect actually fires. */
    data: WebSocketEventData<T> | (() => WebSocketEventData<T> | Promise<WebSocketEventData<T>>);
    roomVars: { [K in WebSocketRoomVars<T>]: string | number };
    socketCtx?: { noExclude?: boolean };
  },
): Effect {
  return async () => {
    // Safety net: an event missing from the rooms map warns instead of
    // crashing the request. (Compare: `resource.websocket` omitted
    // entirely skips the emit at declaration time, before this ever runs.)
    if (!(event in webSocketRoomsMap)) {
      console.warn(`[managers/socket] No rooms map entry for "${event}" — skipping emit.`);
      return;
    }
    const data = typeof opts.data === "function" ? await (opts.data as () => Promise<WebSocketEventData<T>>)() : opts.data;
    socketEmit(event, { data, roomVars: opts.roomVars, noExclude: opts.socketCtx?.noExclude });
  };
}

export function audit(
  action: AuditLogAction,
  opts?: { metadata?: Record<string, unknown>; userId?: number; reason?: string },
): Effect {
  return async () => {
    await triggerAuditLog({ action, metadata: opts?.metadata, userId: opts?.userId, reason: opts?.reason });
  };
}

export function cdnPurge(url: string, zoneEnvVar = "CDN_ZONE_ID"): Effect {
  return async () => {
    const zone_id = process.env[zoneEnvVar];
    if (!zone_id) return; // no-op when unconfigured, e.g. in local dev
    await cdn.cache.purge({ zone_id, files: [url] }).catch(() => {});
  };
}

/**
 * Runs every effect independently — a failure in one never cancels or
 * rolls back another. A downed audit-log destination must never suppress
 * a socket broadcast, or vice versa. `false | null | undefined` entries
 * are skipped, so effects can be included conditionally inline.
 */
export async function runEffects(effects: (Effect | false | null | undefined)[]): Promise<void> {
  const filtered = effects.filter(Boolean) as Effect[];
  await Promise.allSettled(filtered.map((e) => e()));
}
```

Two independent safety nets exist for a missing realtime wiring, on
purpose:

1. **`resource.websocket` omitted entirely** on the manager → `emit()`
   returns `null` before an event name is even computed. This is the
   "this model has no realtime events at all" case.
2. **The event *is* declared but missing from the rooms map** (a
   project-level table saying which room-vars each event needs) → `socket()`
   itself warns and no-ops at call time. This is the "someone declared
   `roomVars` for an event but forgot to register the event elsewhere"
   case — a bug, but one that degrades to a log line instead of a crashed
   request.

A manager assembles its effects list right where the mutation happens:

```ts
await runEffects([
  this.emit("create", populated, row, ctx),
  this.userDeltaEffect("create", row, ctx),
  this.auditFor("create", this.metadataKey(row.id), ctx),
]);
```

`this.emit` / `this.auditFor` / `this.userDeltaEffect` are the base-class
helpers from [api-manager-base](../api-manager-base/SKILL.md) — they read
`resource`/`userDelta` and return `null` when the corresponding config
isn't declared, so this call shape never changes regardless of which
effects a given model actually has.

### Populators — composable, batched read-time enrichment

```ts
// src/lib/managers/base/populator.ts
export interface Populator<DB extends { id: number }> {
  /** Empty batches must return an empty map without hitting the DB. Must not mutate input rows. */
  enrich(rows: DB[]): Promise<Map<number, Record<string, unknown>>>;
}

/**
 * Fans out to every inner populator in parallel over the same row batch,
 * then merges each row's per-populator results. Later populators win on
 * key collisions — put the more specific enrichment last.
 */
export function combinePopulators<DB extends { id: number }>(...populators: Populator<DB>[]): Populator<DB> {
  return {
    async enrich(rows) {
      const merged = new Map<number, Record<string, unknown>>();
      if (rows.length === 0) return merged;

      const results = await Promise.all(populators.map((p) => p.enrich(rows)));
      for (const row of rows) {
        const combined: Record<string, unknown> = {};
        for (const result of results) {
          const chunk = result.get(row.id);
          if (chunk) Object.assign(combined, chunk);
        }
        merged.set(row.id, combined);
      }
      return merged;
    },
  };
}
```

The point of the `Map<id, fields>` shape is that **one row or a thousand
rows cost the same query count** — a populator batches its lookup with
`WHERE id IN (...)` once, never once per row. There is no separate
"turbo"/batched variant to remember to use for list endpoints.

Small reusable populators, composed per model instead of hand-written per
model:

```ts
// A count via a plain foreign key column (e.g. board → posts).
export function columnCountPopulator<DB extends { id: number }>(opts: {
  table: string; column: string; as: string;
}): Populator<DB> { /* one groupBy query, mapped by id */ }

// A numeric aggregate via a plain FK (e.g. board → total post size).
export function sumPopulator<DB extends { id: number }>(opts: {
  table: string; column: string; sumOf: string; as: string;
}): Populator<DB> { /* one groupBy + _sum query, mapped by id */ }

// A count on a polymorphic reference table (referenceType + referenceId).
export function countPopulator<DB extends { id: number }>(opts: {
  table: string; referenceType: number; as: string;
}): Populator<DB> { /* one groupBy query filtered by referenceType, mapped by id */ }
```

A model composes exactly the fields it needs, once, and never touches the
populator again:

```ts
protected readonly populator = combinePopulators<DBBoard>(
  polymorphicPopulator<DBBoard>(ReferenceType.Board, ["share", "likes", "comments"]),
  columnCountPopulator({ table: "post", column: "boardId", as: "postCount" }),
  sumPopulator({ table: "post", column: "boardId", sumOf: "size", as: "totalSize" }),
);
```

### The polymorphic feature table — data-driven, no branches

Several models share the same handful of "polymorphic" cross-cutting
features — a `share` row, `like` count, `comment` count, `view` count —
all keyed by a `(referenceType, referenceId)` pair rather than a direct
foreign key. Instead of `if (opts.share) { ... }` branches repeated per
model, one table maps each feature name to its populator factory and its
owns-cleanup table:

```ts
// src/lib/managers/base/polymorphic.ts
const FEATURES = {
  share: {
    populator: (referenceType: number) => sharePopulator({ referenceType }),
    ownsTable: "share",
  },
  likes: {
    populator: (referenceType: number) => countPopulator({ table: "like", referenceType, as: "likeCount" }),
    ownsTable: "like",
  },
  comments: {
    populator: (referenceType: number) => countPopulator({ table: "comment", referenceType, as: "commentCount" }),
    ownsTable: "comment",
  },
  views: {
    populator: (referenceType: number) => countPopulator({ table: "view", referenceType, as: "viewCount" }),
    ownsTable: "view",
  },
} as const;

export type PolymorphicFeature = keyof typeof FEATURES;

/** No conditional branches — just looks up each requested feature in the table. */
export function polymorphicPopulator<DB extends { id: number }>(
  referenceType: number,
  features: readonly PolymorphicFeature[],
): Populator<DB> {
  return combinePopulators<DB>(...features.map((f) => FEATURES[f].populator(referenceType) as Populator<DB>));
}

/** Order determines delete order. */
export function polymorphicOwns<Row extends { id: number }>(
  referenceType: number,
  features: readonly PolymorphicFeature[],
): OwnsEntry<Row>[] {
  return features.map((f) => ({
    kind: "db" as const,
    table: FEATURES[f].ownsTable,
    where: (row: Row) => ({ referenceType, referenceId: row.id }),
  }));
}
```

Adding a brand-new polymorphic feature (say, `reactions`) to every model
that wants it is **one new row in `FEATURES`**, not a new `if` branch
threaded through every manager that could opt in.

### `redactFromEmits` — fields that never broadcast

```ts
websocket: {
  roomVars: { /* ... */ },
  redactFromEmits: ["passwordHash", "internalNotes"],
},
```

The DB write still receives these fields — only the socket broadcast
doesn't. Applied by the base's `update`/`updateMany` before the diff
(`resolveObjectChanges`) runs, so a patched password can never leak into an
`${name}:update` payload even if a caller passed it.

### The `updateMany` bulk-mutation caveat

`updateMany` (inherited from the base) fires **one realtime emit and one
audit entry per affected row** — deliberately unoptimized, to match the
per-row event contract clients already understand:

```ts
const { count, rows } = await managers.posts.updateMany({
  where: { boardId: { in: staleBoardIds } },
  data: { archived: true },
});
// → `count` rows updated, but also `count` separate `post:update` emits
//   and `count` separate audit-log rows.
```

Fine for tens of rows; noisy at thousands. The fix when it becomes a
problem is a genuinely different code path — a single bulk event carrying
the list of affected ids — not squeezing more rows through the per-row
path.

## Why

Effects are a separate concept from *what triggers them* specifically so a
mutation can be reviewed for "what does this actually do to the outside
world" by reading one array literal, instead of tracing through imperative
code to find every `emit(...)`/`writeAuditLog(...)` call buried in it.
`Promise.allSettled` in `runEffects` is deliberate: an audit-log write
failing must never look, to a client that already got a successful
response and a realtime update, like the operation itself failed.

Populators are batched by construction because the alternative — an
enrichment function written per-row — silently becomes an N+1 query problem
the first time it's used on a list endpoint, and by the time that shows up
in a slow-query log the per-row version is already copied into three other
managers. The polymorphic feature table exists because `switch
(referenceType)` statements for "does this reference type support likes"
were previously scattered across several unrelated files, each with a
slightly different subset of cases, and adding a new reference type meant
finding and updating all of them.

## Exceptions

- `redactFromEmits` is for fields that are sensitive but still legitimately
  stored (passwords, tokens). A field that shouldn't be writable via this
  code path at all belongs in tighter input validation at the route
  boundary, not a redaction list here.
- Reach for the polymorphic feature table only when a feature is genuinely
  shared across multiple unrelated models via a `(referenceType,
  referenceId)` table. A feature specific to one model doesn't need this
  indirection — a plain populator composed directly is simpler.
- The unoptimized `updateMany` is fine as the default; don't pre-build a
  "single bulk event" mechanism before a real bulk-mutation use case
  actually produces enough per-row noise to justify it.

## See also

- [api-manager-base](../api-manager-base/SKILL.md) — where `emit`, `auditFor`, and `userDeltaEffect` are actually called from.
- [api-manager-declarative-config](../api-manager-declarative-config/SKILL.md) — the `resource`/`userDelta`/`shareable` declarations that decide which effects fire.
