---
name: api-manager-declarative-config
description: >-
  The configuration types a concrete manager declares on top of the shared
  base class — resource identity (audit + realtime event naming), shareable
  models, follow-up user-aggregate updates, declarative ownership/cascade
  cleanup on delete, and typed multi-phase delete hooks for genuinely custom
  delete behavior — with full worked examples of a simple cascade-delete
  model and a model with custom delete logic (reassignment + notifications).
  Use when wiring up a new manager's delete cascade, when a delete needs a
  guard or side-effect beyond plain cascading, or when debugging why an
  event/audit entry silently isn't firing. Companion to api-manager-base.
metadata:
  type: practice
  category: architecture
---

## Rule

A concrete manager mostly *declares* rather than *implements*. These are
the pieces it declares, from required to situational.

### `resource` — required identity

```ts
export interface Resource<DB> {
  /** Model name — powers event names, delegate lookup, and metadata key. */
  name: string;
  /** Audit metadata key for `${name}Id`-style entries. Override when the default doesn't match. */
  metadataKey?: string;
  /** AuditLogAction per mutation kind. Omit a kind (or the whole block) to skip audit for it. */
  audit?: Partial<Record<"create" | "update" | "delete", AuditLogAction>>;
  /** Omit the whole block for managers with no socket events. */
  websocket?: {
    roomVars: Record<"create" | "update" | "delete", (row: DB) => Record<string, string | number>>;
    /** Fields never included in an emitted diff, even when patched (e.g. `password`). */
    redactFromEmits?: readonly string[];
  };
}
```

`name` is load-bearing in three places at once: the socket event prefix
(`${name}:create`), the Prisma delegate key (`tx[name].delete(...)` inside
the base's transaction), and the default audit metadata key (`${name}Id`).
**All three must agree** — if the Prisma model is `post`, `resource.name`
must be `"post"`, not `"Post"` or `"posts"`. Diverge and the base fails at
runtime, not at compile time (override with `metadataKey` if the audit
convention genuinely needs to differ).

```ts
protected readonly resource: Resource<DBPost> = {
  name: "post",
  audit: {
    create: AuditLogAction.PostCreate,
    update: AuditLogAction.PostUpdate,
    delete: AuditLogAction.PostDelete,
  },
  websocket: {
    roomVars: {
      create: (row) => ({ boardId: row.boardId }),
      update: (row) => ({ id: row.id, boardId: row.boardId }),
      delete: (row) => ({ id: row.id, boardId: row.boardId }),
    },
    // redactFromEmits: ["internalNote"],
  },
};
```

Skip `audit` (or set `audit: {}`) when no audit-log action exists for the
model yet — the base's `auditFor` returns `null` for a missing kind and
`runEffects` silently skips it. Omit `websocket` entirely for a manager
with no realtime events at all (e.g. an internal-only model) — `emit()`
then returns `null` up front, no wasted lookup.

### `shareable` — models with a polymorphic share row

```ts
export interface Shareable<DB> {
  /** The polymorphic reference-type discriminator for this model's shares. */
  referenceType: number;
  /** Extracts the user id passed to share-code generation. `null` for anonymous codes. */
  ownerFrom?: (row: DB) => number | null;
}
```

```ts
protected readonly shareable: Shareable<DBPost> = {
  referenceType: ReferenceType.Post,
  ownerFrom: (row) => row.userId,
};
```

Declaring this turns `this.createShareRow(tx, row)` (called from your
`create` txn) into a one-liner — see the effects-and-populators skill for
what it actually inserts.

### `userDelta` — follow-up aggregate updates

```ts
export interface UserDelta<DB> {
  on: readonly ("create" | "update" | "delete")[];
  userIdFrom: (row: DB) => number;
  /** Merged with `{ id }` automatically — do not include `id` in the return. */
  fields(userId: number): Promise<Record<string, unknown>>;
}
```

```ts
protected readonly userDelta: UserDelta<DBPost> = {
  on: ["create", "delete"],
  userIdFrom: (row) => row.userId,
  async fields(userId) {
    const postCount = await prisma.post.count({ where: { userId } });
    return { postCount };
  },
};
```

`fields` runs **lazily** — only when the follow-up `user:update` effect
actually fires, inside the socket thunk — so the aggregate query's cost is
only paid when something is listening for it. Don't rely on it running for
a side effect that must always happen; use `deleteFlow.postDelete` (or the
create body) for anything that has to run unconditionally.

### `owns` — declarative delete cascade

```ts
type CascadeTable = "share" | "like" | "comment" | "view"; // extend per project

interface OwnsEntryBase<Row> {
  /** Skip this entry when the predicate returns false — for nullable resources. */
  when?: (row: Row) => boolean;
}

type OwnsEntry<Row> =
  | (OwnsEntryBase<Row> & {
      kind: "db";
      table: CascadeTable;
      where:
        | Record<string, unknown>
        | ((row: Row, tx: Tx) => Record<string, unknown> | Promise<Record<string, unknown>>);
    })
  | (OwnsEntryBase<Row> & { kind: "storage"; bucket: string; key: (row: Row) => string })
  | (OwnsEntryBase<Row> & { kind: "cdn-purge"; url: (row: Row) => string });
```

- `db` entries run **inside** the delete transaction, in list order — so
  cross-model dependencies can be encoded linearly.
- `storage` and `cdn-purge` entries run **after** the transaction commits,
  in parallel, best-effort (failures are swallowed per-entry — a downed S3
  bucket must never prevent a DB delete that already committed from
  staying committed).

```ts
protected readonly owns: OwnsEntry<DBPost>[] = [
  // Comment-likes must be cleared before their parent comments.
  {
    kind: "db",
    table: "like",
    where: async (row, tx) => {
      const comments = await tx.comment.findMany({
        where: { referenceType: ReferenceType.Post, referenceId: row.id },
        select: { id: true },
      });
      return { referenceType: ReferenceType.Comment, referenceId: { in: comments.map((c) => c.id) } };
    },
  },
  { kind: "db", table: "comment", where: (row) => ({ referenceType: ReferenceType.Post, referenceId: row.id }) },
  { kind: "db", table: "like", where: (row) => ({ referenceType: ReferenceType.Post, referenceId: row.id }) },
  {
    kind: "storage",
    bucket: "media",
    key: (row) => row.attachment!.key,
    when: (row) => row.attachment !== null, // nullable field needs the guard
  },
  { kind: "cdn-purge", url: (row) => `https://cdn.example.com/posts/${row.id}` },
];
```

Owned features can differ from *populated* features — a model can populate
`["likes", "comments"]` (what it displays) but own `["likes", "comments",
"views"]` (everything that needs wiping on delete, including a count it
never surfaces to clients).

### `deleteFlow` — typed hooks for genuinely custom delete behavior

```ts
interface DeleteFlow<DB, State = void> {
  /** Throw to abort, or return typed state for the later phases. */
  preDelete?(row: DB, ctx?: MutationCtx): Promise<State>;
  /** Runs inside the transaction, before owned-cleanup and the parent delete. */
  deleteInTxn?(row: DB, tx: Tx, state: State, ctx?: MutationCtx): Promise<void>;
  /** Extra effects to fan out alongside the standard delete effects. */
  postDelete?(row: DB, state: State, ctx?: MutationCtx): Promise<Effect[] | void>;
}
```

The `State` generic threads typed data between the three phases —
**never** stash phase data on `this`; concurrent deletes on the same
manager instance would clobber each other's scratch state.

Full worked example — deleting a workspace reassigns its members to a
default workspace instead of cascading their rows away, and notifies each
affected member:

```ts
// src/lib/managers/workspaces.ts
import { z } from "pumice.js";
import { DBWorkspaceSchema, WorkspaceSchema } from "@/lib/schemas/general";
import { prisma } from "@/lib/prisma";
import {
  BaseManager,
  DeleteFlow,
  Effect,
  MutationCtx,
  Resource,
  columnCountPopulator,
  combinePopulators,
  socket,
} from "./base";
import { DEFAULT_WORKSPACE_ID } from "@/lib/constants";

type DBWorkspace = z.infer<typeof DBWorkspaceSchema>;
type Workspace = z.infer<typeof WorkspaceSchema>;

interface WorkspaceDeleteState {
  members: { id: number }[];
}

export interface WorkspaceCreateInput {
  name: string;
  ownerId: number;
}

/**
 * Unlike Post, a workspace has no shares/likes/comments and no follow-up
 * `user:update` on create — so neither `shareable` nor `userDelta` is
 * declared. Delete does **not** cascade members: they're reassigned to
 * the default workspace via `deleteFlow`, and each gets notified.
 */
export class WorkspaceManager extends BaseManager<typeof prisma.workspace, DBWorkspace, Workspace> {
  protected readonly model = prisma.workspace;

  protected readonly resource: Resource<DBWorkspace> = {
    name: "workspace",
    audit: {}, // no AuditLogAction entries exist for this model yet
    websocket: {
      roomVars: {
        create: (row) => ({ id: row.id }),
        update: (row) => ({ id: row.id }),
        delete: (row) => ({ id: row.id }),
      },
    },
  };

  protected readonly populator = combinePopulators<DBWorkspace>(
    columnCountPopulator({ table: "user", column: "workspaceId", as: "memberCount" }),
  );

  protected readonly deleteFlow: DeleteFlow<DBWorkspace, WorkspaceDeleteState> = {
    preDelete: async (row) => ({
      members: await prisma.user.findMany({ where: { workspaceId: row.id }, select: { id: true } }),
    }),

    deleteInTxn: async (_row, tx, { members }) => {
      if (members.length === 0) return;
      await tx.user.updateMany({
        where: { id: { in: members.map((m) => m.id) } },
        data: { workspaceId: DEFAULT_WORKSPACE_ID },
      });
    },

    postDelete: async (_row, { members }) => {
      // Best-effort, parallel — a notification failure shouldn't roll back the delete.
      await Promise.allSettled(
        members.map((m) =>
          prisma.notification.create({
            data: {
              userId: m.id,
              type: "Warning",
              title: "Your workspace was deleted",
              message: "You've been moved to the default workspace.",
            },
          }),
        ),
      );

      const effects: Effect[] = members.map((m) =>
        socket("user:update", { data: { id: m.id, workspaceId: DEFAULT_WORKSPACE_ID }, roomVars: { id: m.id } }),
      );
      return effects;
    },
  };

  async create(input: WorkspaceCreateInput, ctx?: MutationCtx): Promise<Workspace> {
    const row = (await prisma.workspace.create({
      data: { name: input.name, ownerId: input.ownerId },
    })) as DBWorkspace;

    // A fresh workspace always has zero members — skip the populate query.
    return this.finishCreate(row, ctx, { populated: { ...row, memberCount: 0 } });
  }
}
```

A second recipe — a "reject delete unless empty" guard, no in-txn work and
no extra effects, just `preDelete` throwing:

```ts
protected readonly deleteFlow: DeleteFlow<DBBoard, void> = {
  preDelete: async (row) => {
    const postCount = await prisma.post.count({ where: { boardId: row.id } });
    if (postCount > 0) {
      throw new Error("Cannot delete a board that still has posts");
    }
  },
};
```

### `MutationCtx` — the request boundary, explicit

```ts
export interface MutationCtx {
  /** Override/augment the audit-log entry. `metadata` merges with the manager's own (caller wins on collision). */
  audit?: { userId?: number; reason?: string; metadata?: Record<string, unknown> };
  /** `noExclude: true` broadcasts to every connection in the room, including the requester's own. */
  socket?: { noExclude?: boolean };
}
```

Routes are the only place request state gets read at all. Whatever a
manager needs from the request — the actor id, an audit-log reason header,
a client-supplied field that changes business logic — gets extracted in
the route handler and passed in explicitly:

```ts
await managers.posts.create(
  { userId: c.auth.data.user.id, boardId: c.body.boardId, title: c.body.title, body: c.body.body },
  { audit: { reason: c.req.header("X-Audit-Log-Reason") } },
);
```

A background job or cron schedule calling the same manager method passes
its own actor id and reason instead of `undefined` — the manager code
itself never branches on "am I inside an HTTP request."

## Why

Configuration that's declared once is reviewable in a checklist; behavior
that's re-implemented per model drifts silently. `resource.name` collisions
are the sharpest version of this: three different subsystems (sockets,
Prisma delegate lookup, audit metadata) all key off one string, so a typo
fails at *runtime*, in production, the first time that code path actually
runs — not at compile time. `deleteFlow`'s typed `State` generic exists
specifically because the first version of this pattern stored phase data
on `this`, and two concurrent deletes on the same manager instance
clobbered each other's snapshot.

## Exceptions

- A model whose delete is simply forbidden by policy overrides `delete`
  directly and throws — that's not something `deleteFlow` needs to express,
  since there's no cascade or reassignment happening at all.
- `deleteFlow.postDelete`'s best-effort, `Promise.allSettled`-wrapped
  notifications are the right default for "nice to have, must not block the
  delete." A notification that's actually required (e.g. a compliance
  record) shouldn't be fire-and-forget — do that write inside
  `deleteInTxn` instead, where a failure rolls back the whole delete.

## See also

- [api-manager-base](../api-manager-base/SKILL.md) — the base class that reads all of the config declared here.
- [api-manager-effects-and-populators](../api-manager-effects-and-populators/SKILL.md) — the `Effect`/populator machinery `resource`, `userDelta`, and `owns` ultimately drive.
