---
name: api-manager-base
description: >-
  The generic base class at the center of the declarative manager pattern —
  implements find/fetch, populate, update, delete, and create-finishing, so
  a concrete model's manager only writes its create() method plus a page of
  declarative config. Use when adding a new domain manager for a model, when
  deciding what belongs in the shared base class versus a subclass, or when
  writing the one bespoke create() method a new model needs (including the
  file-upload + rollback variant). Companion skills:
  api-manager-declarative-config (resource/shareable/userDelta/owns/deleteFlow)
  and api-manager-effects-and-populators (sockets, audit, populator
  composition).
metadata:
  type: practice
  category: architecture
---

## Rule

Model domain logic as manager classes extending one generic
`BaseManager<Model, DB, Populated>` instead of one bespoke class per model.
The base implements everything that's the same shape across every model;
subclasses declare configuration and write one method: `create`.

### The base class, in full

```ts
// src/lib/managers/base/base-manager.ts
import type { Prisma } from "@/generated/prisma/client";
import { prisma } from "@/lib/prisma";
import { resolveObjectChanges } from "@/lib/utils";
import { Populator } from "./populator";
import { OwnsEntry, runOwnedDbCleanup, runOwnedExternalCleanup } from "./owns";
import { Effect, audit, runEffects, socket } from "./effects";
import {
  DeleteFlow,
  MutationCtx,
  Resource,
  Shareable,
  SocketKind,
  UserDelta,
} from "./types";
import { WebSocketEmittableEvent, WebSocketEventData } from "@/lib/websocket/types";

type Tx = Prisma.TransactionClient;

/**
 * Minimum prisma delegate shape the base leans on. Structural — prisma's
 * real delegate types wrap results in `GetResult<...>` layers we don't
 * track here, so the base casts back to `DB` at the seam where it hands
 * rows to concrete managers.
 */
export interface PrismaModelDelegate {
  findUnique(args: any): Promise<any>;
  findFirst(args?: any): Promise<any>;
  findMany(args?: any): Promise<any>;
  update(args: any): Promise<any>;
  updateMany(args: any): Promise<any>;
  delete(args: any): Promise<any>;
}

/**
 * Base for domain managers.
 *
 * Read surface splits into `find*` (raw DB row) and `fetch*` (populated) —
 * no `populate: boolean` flag, no overloads, no separate "turbo" variant.
 *
 * Mutation surface is provided out of the box: `update` and `delete` are
 * implemented here; subclasses only override for genuine policy
 * differences. `finishCreate` wraps up the post-create ceremony (populate,
 * emit, follow-up `user:update`, audit) so a subclass's `create` body
 * focuses purely on model-specific work.
 *
 * @typeParam Model - Prisma delegate for the model (`typeof prisma.post`).
 * @typeParam DB - Raw DB row shape.
 * @typeParam Populated - Enriched shape returned by `fetch*` / `populate*`.
 */
export abstract class BaseManager<
  Model extends PrismaModelDelegate,
  DB extends { id: number },
  Populated extends DB,
> {
  protected abstract readonly model: Model;
  protected abstract readonly resource: Resource<DB>;
  protected abstract readonly populator: Populator<DB>;

  protected readonly owns: OwnsEntry<DB>[] = [];
  protected readonly shareable?: Shareable<DB>;
  protected readonly userDelta?: UserDelta<DB>;
  protected readonly deleteFlow?: DeleteFlow<DB, any>;

  /* ------------------------------------------------------------ Reads */

  /** Raw row by id, or `null`. Same arg shape as `prisma.<model>.findUnique`. */
  async find(args: Parameters<Model["findUnique"]>[0]): Promise<DB | null> {
    return (await this.model.findUnique(args)) as DB | null;
  }

  async findFirst(args?: Parameters<Model["findFirst"]>[0]): Promise<DB | null> {
    return (await this.model.findFirst(args)) as DB | null;
  }

  async findMany(args?: Parameters<Model["findMany"]>[0]): Promise<DB[]> {
    return (await this.model.findMany(args)) as DB[];
  }

  /* --------------------------------------------------- Populated reads */

  /** `find` + `populateOne`. Enrichment only runs for a present row. */
  async fetch(args: Parameters<Model["findUnique"]>[0]): Promise<Populated | null> {
    const row = await this.find(args);
    return row ? this.populateOne(row) : null;
  }

  /** `findMany` + one batched `populate` pass, regardless of result size. */
  async fetchMany(args?: Parameters<Model["findMany"]>[0]): Promise<Populated[]> {
    const rows = await this.findMany(args);
    return this.populate(rows);
  }

  /* -------------------------------------------------------- Population */

  /**
   * Runs the manager's populator over `rows`, merging each row with its
   * enrichment fields. Exactly one batched query per inner populator,
   * regardless of how many rows are passed in. Empty input short-circuits
   * without hitting the DB.
   */
  async populate(rows: DB[]): Promise<Populated[]> {
    if (rows.length === 0) return [];
    const enrichmentMap = await this.populator.enrich(rows);
    return rows.map((row) => ({ ...row, ...enrichmentMap.get(row.id) }) as Populated);
  }

  async populateOne(row: DB): Promise<Populated> {
    const [populated] = await this.populate([row]);
    return populated;
  }

  /* ------------------------------------------------------------- Mutations */

  /**
   * Applies a partial update and broadcasts the change.
   *
   * `data` mirrors Prisma's `update.data` shape exactly — plain values,
   * atomic operators (`{ increment: 1 }`, `{ set: "x" }`, `{ push: [...] }`),
   * nested writes — so callers get full autocomplete on fields and their
   * allowed operators.
   *
   * The emitted `${name}:update` payload contains only the keys that were
   * actually patched — the diff is computed via
   * `resolveObjectChanges(row, data)`, reading *post-update* values off the
   * row, so `{ downloads: { increment: 1 } }` becomes `{ downloads: 42 }`
   * in the emit. `resource.websocket.redactFromEmits` fields are stripped
   * first. A `userDelta`-declared kind fires a follow-up `user:update`.
   * A `resource.audit.update` entry writes an audit-log row.
   */
  async update(
    id: number,
    data: Parameters<Model["update"]>[0]["data"],
    ctx?: MutationCtx,
  ): Promise<Populated> {
    const row = (await this.model.update({ where: { id }, data })) as DB;
    const populated = await this.populateOne(row);
    const emitInput = this.stripRedacted(data as Record<string, unknown>);

    await runEffects([
      this.emit("update", { id: row.id, ...resolveObjectChanges(row, emitInput) }, row, ctx),
      this.userDeltaEffect("update", row, ctx),
      this.auditFor("update", this.metadataKey(row.id), ctx),
    ]);

    return populated;
  }

  /**
   * ⚠️ Unoptimized. Applies the same patch to every row matching
   * `args.where`, then fires an individual `${name}:update` emit + audit
   * entry **per row** — N socket messages and N audit rows per bulk call.
   * See the effects-and-populators skill for the roadmap to a single bulk
   * event.
   */
  async updateMany(
    args: Parameters<Model["updateMany"]>[0],
    ctx?: MutationCtx,
  ): Promise<{ count: number; rows: DB[] }> {
    const argsAsAny = args as { where?: unknown; data?: unknown };

    const { count, rows } = await this.txn(async (tx) => {
      const model = (tx as any)[this.resource.name];
      const { count } = await model.updateMany(args);
      const rows = (await model.findMany({ where: argsAsAny.where })) as DB[];
      return { count, rows };
    });

    if (rows.length === 0) return { count, rows };

    const emitInput = this.stripRedacted((argsAsAny.data ?? {}) as Record<string, unknown>);

    await runEffects(
      rows.flatMap((row) => [
        this.emit("update", { id: row.id, ...resolveObjectChanges(row, emitInput) }, row, ctx),
        this.auditFor("update", this.metadataKey(row.id), ctx),
      ]),
    );

    return { count, rows };
  }

  /**
   * Deletes a row and everything declared on `owns`, plus any custom work
   * declared via `deleteFlow`.
   *
   * Order: load the row (throws on 404) → `deleteFlow.preDelete` (guards,
   * snapshots) → inside a transaction: `deleteFlow.deleteInTxn`, owned DB
   * cleanup, then the parent row delete → owned external cleanup
   * (storage/CDN, best-effort, after commit) → `deleteFlow.postDelete`
   * (extra effects) → standard delete effects (`user:update` if declared,
   * `${name}:delete` emit, audit entry).
   */
  async delete(id: number, ctx?: MutationCtx): Promise<void> {
    const row = await this.findOrThrow(id);
    const state = (await this.deleteFlow?.preDelete?.(row, ctx)) as unknown;

    await this.txn(async (tx) => {
      await this.deleteFlow?.deleteInTxn?.(row, tx, state, ctx);
      await this.cleanupOwnedInTxn(row, tx);
      await (tx as any)[this.resource.name].delete({ where: { id } });
    });

    await this.cleanupOwnedExternal(row);

    const extraEffects = (await this.deleteFlow?.postDelete?.(row, state, ctx)) ?? [];

    await runEffects([
      ...extraEffects,
      this.userDeltaEffect("delete", row, ctx),
      this.emit("delete", { id }, row, ctx),
      this.auditFor("delete", this.metadataKey(id), ctx),
    ]);
  }

  /**
   * Wraps up the post-create ceremony: populate the row, emit
   * `${name}:create`, fire the follow-up `user:update` (when `userDelta`
   * opts into `"create"`), write the audit entry.
   *
   * A subclass `create` does its model-specific work (S3, custom field
   * mapping, share-row insertion), then hands the raw row to this method
   * and returns its result.
   *
   * `opts.populated` lets a caller skip the populate query when it already
   * knows the result (a fresh row's derived count is always zero).
   */
  protected async finishCreate(
    row: DB,
    ctx?: MutationCtx,
    opts?: { populated?: Populated },
  ): Promise<Populated> {
    const populated = opts?.populated ?? (await this.populateOne(row));

    await runEffects([
      this.emit("create", populated, row, ctx),
      this.userDeltaEffect("create", row, ctx),
      this.auditFor("create", this.metadataKey(row.id), ctx),
    ]);

    return populated;
  }

  /* ---------------------------------------------------- Effect helpers */
  // See api-manager-effects-and-populators for `emit`, `auditFor`,
  // `metadataKey`, `userDeltaEffect`, `stripRedacted`, and `createShareRow`.

  protected emit(kind: SocketKind, data: unknown, row: DB, ctx?: MutationCtx): Effect | null {
    if (!this.resource.websocket) return null;
    const event = `${this.resource.name}:${kind}` as WebSocketEmittableEvent;
    return socket(event, {
      data: data as WebSocketEventData<typeof event>,
      roomVars: this.resource.websocket.roomVars[kind](row) as any,
      socketCtx: ctx?.socket,
    });
  }

  private stripRedacted(input: Record<string, unknown>): Record<string, unknown> {
    const redacted = this.resource.websocket?.redactFromEmits;
    if (!redacted || redacted.length === 0) return input;
    const out = { ...input };
    for (const key of redacted) delete out[key];
    return out;
  }

  protected auditFor(kind: SocketKind, extraMetadata: Record<string, unknown>, ctx?: MutationCtx): Effect | null {
    const action = this.resource.audit?.[kind];
    if (!action) return null;
    return audit(action, {
      metadata: { ...extraMetadata, ...ctx?.audit?.metadata },
      userId: ctx?.audit?.userId,
      reason: ctx?.audit?.reason,
    });
  }

  protected metadataKey(id: number): Record<string, number> {
    const key = this.resource.metadataKey ?? `${this.resource.name}Id`;
    return { [key]: id };
  }

  protected userDeltaEffect(kind: SocketKind, row: DB, ctx?: MutationCtx): Effect | null {
    if (!this.userDelta || !this.userDelta.on.includes(kind)) return null;
    const userId = this.userDelta.userIdFrom(row);
    const delta = this.userDelta;
    return socket("user:update", {
      data: async () => ({ id: userId, ...(await delta.fields(userId)) }),
      roomVars: { id: userId },
      socketCtx: ctx?.socket,
    });
  }

  /** No-op when `shareable` isn't declared — safe to call unconditionally from `create`. */
  protected async createShareRow(tx: Tx, row: DB): Promise<void> {
    if (!this.shareable) return;
    const userId = this.shareable.ownerFrom?.(row) ?? undefined;
    const { managers } = await import("./index");
    await tx.share.create({
      data: {
        referenceType: this.shareable.referenceType,
        referenceId: row.id,
        code: await managers.shares.generateCode(userId ?? undefined),
      },
    });
  }

  /* -------------------------------------------------------- Owned cleanup */

  protected cleanupOwnedInTxn(row: DB, tx: Tx): Promise<void> {
    return runOwnedDbCleanup(row, this.owns, tx);
  }

  protected cleanupOwnedExternal(row: DB): Promise<void> {
    return runOwnedExternalCleanup(row, this.owns);
  }

  /* ------------------------------------------------------------- Read helpers */

  protected async findOrThrow(id: number): Promise<DB> {
    const row = await this.find({ where: { id } });
    if (!row) throw new Error(`${this.resource.name} ${id} not found`);
    return row;
  }

  /* ------------------------------------------------------------ Transaction */

  protected txn<T>(fn: (tx: Tx) => Promise<T>): Promise<T> {
    return prisma.$transaction(fn);
  }
}
```

### A simple manager: no file upload

A model with no shares/likes/comments, no storage, no custom delete
behavior — the base does almost everything, `create` is a couple of lines:

```ts
// src/lib/managers/posts.ts
import { z } from "pumice.js";
import { DBPostSchema, PostSchema } from "@/lib/schemas/general";
import { prisma } from "@/lib/prisma";
import { BaseManager, MutationCtx, Resource, columnCountPopulator } from "./base";

type DBPost = z.infer<typeof DBPostSchema>;
type Post = z.infer<typeof PostSchema>;

export interface PostCreateInput {
  userId: number;
  boardId: number;
  title: string;
  body: string;
}

export class PostManager extends BaseManager<typeof prisma.post, DBPost, Post> {
  protected readonly model = prisma.post;

  protected readonly resource: Resource<DBPost> = {
    name: "post",
    audit: { create: "PostCreate", update: "PostUpdate", delete: "PostDelete" },
    websocket: {
      roomVars: {
        create: (row) => ({ boardId: row.boardId }),
        update: (row) => ({ id: row.id, boardId: row.boardId }),
        delete: (row) => ({ id: row.id, boardId: row.boardId }),
      },
    },
  };

  protected readonly populator = columnCountPopulator({
    table: "comment",
    column: "postId",
    as: "commentCount",
  });

  async create(input: PostCreateInput, ctx?: MutationCtx): Promise<Post> {
    const row = (await prisma.post.create({
      data: { userId: input.userId, boardId: input.boardId, title: input.title, body: input.body },
    })) as DBPost;

    return this.finishCreate(row, ctx, { populated: { ...row, commentCount: 0 } });
  }
}
```

`update` and `delete` need no overrides at all — they're fully inherited.

### A manager with file upload — `StorageUpload` + rollback

Any `create` that writes to external storage follows the same shape:
upload first, write the DB row inside a transaction, roll the upload back
if the transaction fails.

```ts
// src/lib/managers/base/storage-upload.ts
import { PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import imageSize from "image-size";
import { s3 } from "@/lib/s3";
import { randomKey } from "@/lib/helpers/random";
import { compressImage } from "@/lib/functions/image-compressor";

export interface StorageUploadOptions {
  bucket: string;
  file: File;
  filename?: string;
  compress?: false | { quality: number };
  detectDimensions?: boolean;
}

export interface UploadResult {
  key: string;
  bucket: string;
  filename: string;
  size: number;
  mime: string;
  dimensions?: { width: number; height: number };
  /** Best-effort cleanup for a transaction's catch block. Swallows its own errors. */
  rollback: () => Promise<void>;
}

export class StorageUpload {
  static async perform(opts: StorageUploadOptions): Promise<UploadResult> {
    const key = randomKey({ prefixLength: 4 });
    const originalBuffer = Buffer.from(await opts.file.arrayBuffer());

    const buffer = opts.compress
      ? (await compressImage(originalBuffer, { mimeType: opts.file.type, quality: opts.compress.quality })).buffer
      : originalBuffer;

    await s3.send(new PutObjectCommand({ Bucket: opts.bucket, Key: key, Body: buffer, ContentType: opts.file.type }));

    let dimensions: { width: number; height: number } | undefined;
    if (opts.detectDimensions) {
      const d = imageSize(buffer);
      if (d.width === undefined || d.height === undefined) {
        throw new Error("Failed to read image dimensions");
      }
      dimensions = { width: d.width, height: d.height };
    }

    return {
      key,
      bucket: opts.bucket,
      filename: opts.filename ?? opts.file.name,
      size: buffer.length,
      mime: opts.file.type,
      dimensions,
      rollback: async () => {
        await s3.send(new DeleteObjectCommand({ Bucket: opts.bucket, Key: key })).catch(() => {});
      },
    };
  }
}
```

```ts
// src/lib/utils/with-rollback.ts
export async function withRollback<T>(
  fn: () => Promise<T>,
  rollback: () => Promise<void>,
): Promise<T> {
  try {
    return await fn();
  } catch (err) {
    await rollback();
    throw err;
  }
}
```

Put together in a manager:

```ts
// src/lib/managers/media-assets.ts
import { z } from "pumice.js";
import { DBMediaAssetSchema, MediaAssetSchema } from "@/lib/schemas/general";
import { ReferenceType } from "@/lib/typings/sdk-types";
import { prisma } from "@/lib/prisma";
import { withRollback } from "@/lib/utils";
import {
  BaseManager,
  MutationCtx,
  OwnsEntry,
  Resource,
  Shareable,
  StorageUpload,
  UserDelta,
  combinePopulators,
  polymorphicOwns,
  polymorphicPopulator,
} from "./base";

type DBMediaAsset = z.infer<typeof DBMediaAssetSchema>;
type MediaAsset = z.infer<typeof MediaAssetSchema>;

export interface MediaAssetCreateInput {
  file: File;
  userId: number;
  folderId?: number | null;
}

export class MediaAssetManager extends BaseManager<
  typeof prisma.mediaAsset,
  DBMediaAsset,
  MediaAsset
> {
  protected readonly model = prisma.mediaAsset;

  protected readonly resource: Resource<DBMediaAsset> = {
    name: "mediaAsset",
    audit: { create: "MediaAssetCreate", update: "MediaAssetUpdate", delete: "MediaAssetDelete" },
    websocket: {
      roomVars: {
        create: (row) => ({ userId: row.userId }),
        update: (row) => ({ id: row.id, userId: row.userId }),
        delete: (row) => ({ id: row.id, userId: row.userId }),
      },
    },
  };

  protected readonly shareable: Shareable<DBMediaAsset> = {
    referenceType: ReferenceType.MediaAsset,
    ownerFrom: (row) => row.userId,
  };

  protected readonly userDelta: UserDelta<DBMediaAsset> = {
    on: ["create", "delete"],
    userIdFrom: (row) => row.userId,
    async fields(userId) {
      const { _sum } = await prisma.mediaAsset.aggregate({ _sum: { size: true }, where: { userId } });
      return { storageUsed: _sum.size ?? 0 };
    },
  };

  protected readonly populator = combinePopulators<DBMediaAsset>(
    polymorphicPopulator<DBMediaAsset>(ReferenceType.MediaAsset, ["share", "likes"]),
  );

  protected readonly owns: OwnsEntry<DBMediaAsset>[] = [
    ...polymorphicOwns<DBMediaAsset>(ReferenceType.MediaAsset, ["share", "likes"]),
    { kind: "storage", bucket: "media", key: (row) => row.storageKey },
    { kind: "cdn-purge", url: (row) => `https://cdn.example.com/media/${row.storageKey}` },
  ];

  async create(input: MediaAssetCreateInput, ctx?: MutationCtx): Promise<MediaAsset> {
    const upload = await StorageUpload.perform({
      bucket: "media",
      file: input.file,
      compress: { quality: 82 },
      detectDimensions: true,
    });

    const row = await withRollback(
      () =>
        this.txn(async (tx) => {
          const asset = (await tx.mediaAsset.create({
            data: {
              userId: input.userId,
              folderId: input.folderId ?? null,
              filename: upload.filename,
              size: upload.size,
              width: upload.dimensions!.width,
              height: upload.dimensions!.height,
              storageKey: upload.key,
            },
          })) as DBMediaAsset;

          await this.createShareRow(tx, asset);
          return asset;
        }),
      upload.rollback,
    );

    return this.finishCreate(row, ctx);
  }
}
```

`withRollback` guarantees: if the transaction fails for any reason (a
unique constraint, a downstream throw), the just-uploaded object is deleted
before the error propagates — no orphaned files left behind by a failed
write.

## Why

Every hand-written manager in a growing API converges on the same shape —
CRUD methods that each inline the same handful of concerns (external
storage, realtime events, audit logging, cascading deletes, derived
counts) — and the copy-paste drifts: one model's delete forgets to clean up
a cache entry, another's create forgets the audit log. Pulling the *shared
machinery* into a generic base and reducing each concrete model to
*configuration* turns a missing case into a missing declaration — easy to
spot in review — instead of a missing line buried in a hundred lines of
imperative code. It also makes the domain layer testable without an HTTP
request in scope, since nothing in the base (or in a well-written subclass)
reads ambient request state — see `MutationCtx` in the
declarative-config skill for how request-derived data gets in instead.

## Exceptions

- Not worth it below roughly three or four models with real CRUD plus
  side-effects — the base class is pure overhead until there's enough
  repetition to justify sharing it. A single-model service should just
  write the CRUD directly.
- Read-heavy, mutation-light models (pure lookup tables, config) don't need
  manager machinery at all — a thin query module is enough.
- Overriding `update`/`delete` is legitimate for genuine policy
  differences (a model whose delete is simply forbidden and should throw).
  It's *not* legitimate to override either method just to skip a
  side-effect the declarative config in the companion skill could express
  instead — that's a sign the declaration is missing a case, not that the
  base doesn't fit.

## See also

- [api-manager-declarative-config](../api-manager-declarative-config/SKILL.md) — the `resource` / `shareable` / `userDelta` / `owns` / `deleteFlow` fields this base class reads.
- [api-manager-effects-and-populators](../api-manager-effects-and-populators/SKILL.md) — what `emit`, `auditFor`, `userDeltaEffect`, and the populator actually do underneath.
- [api-route-procedures](../../routing/api-route-procedures/SKILL.md) — the route-layer counterpart that resolves a row before a manager method ever runs.
