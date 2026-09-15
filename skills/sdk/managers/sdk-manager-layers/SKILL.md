---
name: sdk-manager-layers
description: >-
  The three-layer architecture for a client SDK wrapping a cached, typed
  API — structures (one instance's fields + thin delegation), top-level
  managers (the single global cache + fetch/create/edit/delete for one
  resource type via a generic CachedManager base), and sub-managers (a
  scoped, filtered view over a parent's cache, no second source of truth).
  Use when adding a new resource type to an SDK, adding a scoped
  collection on an existing structure (e.g. "a user's folders"), or
  deciding whether new code belongs on a structure, a top-level manager, or
  a sub-manager. Companions: sdk-resolvable-ids, sdk-cache-update-placement,
  sdk-naming-conventions, sdk-file-section-order.
metadata:
  type: practice
  category: architecture
---

## Rule

Three layers, each with one job. Sub-managers must never invent a second
source of truth for entities the top-level manager already caches.

| Layer | Owns | Primary job |
| --- | --- | --- |
| **Structure** | One instance's fields + its sub-managers | Thin delegation to managers; applies local patches only when the update is clearly about *this* instance |
| **Top-level manager** | The canonical cache for one resource type | HTTP + cache lifecycle: fetch/create/edit/delete, via a generic base |
| **Sub-manager** | No separate cache | Routes scoped API calls through the matching top-level manager so responses still land in the *one* global cache |

### `Base` — the structure base class

```ts
// src/structures/base.ts
export abstract class Base {
  protected hematite: Client;
  public id: number;

  constructor(client: Client, id: number) {
    this.hematite = client;
    this.id = id;
  }

  /** Whether required fields are missing — overridden per structure. */
  public get partial(): boolean {
    return false;
  }

  public $clone(): this {
    return Object.assign(Object.create(this), this);
  }

  /** Merges new/initial data onto this instance. */
  public $patch(data: unknown): void {
    Object.assign(this, data);
  }

  /** Applies new data and returns a clone of the pre-update state. */
  public $update(data: unknown): this {
    const clone = this.$clone();
    this.$patch(data);
    return clone;
  }

  public toJSON(): string {
    return JSON.stringify({ $structure: this.constructor.name, id: this.id });
  }

  public valueOf(): number {
    return this.id;
  }
}
```

Every structure extends `Base` and adds fields + resource-specific methods
on top. `$update`'s "return the pre-update clone" shape matters: callers
that need to diff or roll back a local optimistic update get the old
instance back for free, instead of having to snapshot it themselves before
calling `$patch`.

### `CachedManager` — the generic top-level manager base

```ts
// src/managers/cached-manager.ts
export interface ApiStructure {
  id: number;
}

export abstract class CachedManager<
  Holds extends Base,
  ApiHolds extends ApiStructure,
> extends BaseManager {
  private holds: Constructable<Holds>;
  private readonly _cache = new Collection<number, Holds>();

  constructor(client: Client, holds: Constructable<Holds>) {
    super(client);
    this.holds = holds;
  }

  public get cache(): Collection<number, Holds> {
    return this._cache;
  }

  /** Structure or its id, resolved to the id. */
  public resolveId(structure: Holds | number): number {
    if (structure instanceof this.holds) return structure.id;
    return structure as number;
  }

  /** Cache hit (unless `force`) or fetch-then-cache. */
  public async $fetchSingle<S extends PartialStructure<ApiHolds>>({
    id, fn, force = false, cache = true,
  }: { id: number | null; fn: () => Promise<S> } & BaseFetchOptions): Promise<Holds> {
    if (!force && id !== null) {
      const existing = this.cache.get(id);
      if (existing && !existing.partial) return existing;
    }
    const response = await fn();
    return this.$add(response, { cache });
  }

  /** Always hits the API; does not check the cache first. */
  public async $fetchMany<S extends PartialStructure<ApiHolds>>({
    fn, cache = true,
  }: { fn: () => Promise<S[]> } & BaseFetchOptions): Promise<Collection<number, Holds>> {
    const response = await fn();
    const collection = new Collection<number, Holds>();
    for (const item of response) collection.set(item.id, this.$add(item, { cache }));
    return collection;
  }

  public async $createSingle({
    fn, cache = true,
  }: { fn: () => Promise<ApiHolds> } & BaseFetchOptions): Promise<Holds> {
    const created = await fn();
    return this.$add(created, { cache });
  }

  public async $editSingle({
    id, data, fn,
  }: { id: number; data: Partial<ApiHolds>; fn: () => Promise<PartialStructure<ApiHolds>> }): Promise<Holds> {
    const existing = this.cache.get(id);
    const edited = await fn();
    return existing ? existing.$update(data) : this.$add(edited);
  }

  public async $deleteSingle({ id, fn }: { id: number; fn: () => Promise<void> }): Promise<void> {
    await fn();
    const existing = this.cache.get(id);
    if (existing) this.cache.delete(existing.id);
  }

  /** Inserts or merges a raw API row into the cache and returns the structure instance. */
  public $add(
    data: PartialStructure<ApiHolds>,
    { id, cache = true }: { id?: number; cache?: boolean } = {},
  ): Holds {
    const existing = this.cache.get(id ?? data.id);
    if (existing) {
      if (cache) {
        existing.$patch(data);
        return existing;
      }
      const clone = existing.$clone();
      clone.$patch(data);
      return clone;
    }

    const entry = new this.holds(this.hematite, data);
    if (cache) this.cache.set(id ?? entry.id, entry);
    return entry;
  }
}
```

A concrete top-level manager subclasses `CachedManager<Structure, ApiDto>`
and calls these `$`-helpers from its public methods — it never re-merges
cache state or re-derives "is this a hit" logic by hand:

```ts
// src/managers/domain-manager.ts
export class DomainManager extends CachedManager<Domain, ApiDomain> {
  constructor(client: Client) {
    super(client, Domain);
  }

  public fetch(domain: DomainResolvable, options?: BaseFetchOptions): Promise<Domain>;
  public fetch(): Promise<Collection<number, Domain>>;
  public fetch(domain?: DomainResolvable, { cache = true, force = false }: BaseFetchOptions = {}) {
    if (domain) {
      const id = this.resolveId(domain);
      return this.$fetchSingle({ id, fn: () => this.hematite.$api.domains.$(id).get(), cache, force });
    }
    throw new Error("Not implemented"); // no "list all domains" endpoint yet — see sdk conventions on stubs
  }

  public create(data: DomainCreateBody): Promise<Domain> {
    return this.$createSingle({ fn: () => this.hematite.$api.domains.post({ body: data }) });
  }

  public edit(domain: DomainResolvable, data: DomainEditBody): Promise<Domain> {
    const id = this.resolveId(domain);
    return this.$editSingle({ id, data, fn: () => this.hematite.$api.domains.$(id).patch({ body: data }) });
  }
}
```

### `BaseManager` — the minimal shared base for sub-managers too

```ts
// src/managers/base-manager.ts
export abstract class BaseManager {
  protected hematite: Client;
  constructor(client: Client) {
    this.hematite = client;
  }
}
```

`CachedManager extends BaseManager` — sub-managers extend `BaseManager`
directly (not `CachedManager`, since they hold no cache of their own).

### A sub-manager: filtered view, not a second cache

```ts
// src/managers/user-invite-manager.ts
export class UserInviteManager extends BaseManager {
  private user: User;

  constructor(client: Client, user: User) {
    super(client);
    this.user = user;
  }

  get cache(): Collection<number, Invite> {
    return this.hematite.invites.cache.filter((invite) => invite.userId === this.user.id);
  }

  fetch(): Promise<Collection<number, Invite>> {
    return this.hematite.invites.$fetchMany({
      fn: () => this.hematite.$api.users.$(this.user.id).invites.get(),
    });
  }
}
```

`cache` is a **filter over the top-level manager's cache** — never a second
`Collection` holding duplicate `Invite` instances. `fetch()` still calls
`this.hematite.invites.$fetchMany` (the top-level manager), just with a
scoped API route — so results merge into the one cache every other view of
`Invite` reads from. Attached on the parent structure's field initializer:

```ts
// src/structures/user.ts
export class User extends Base {
  public invites = new UserInviteManager(this.hematite, this);
  // ...
}
```

### Derived-membership sub-managers — the exception to "always fetch"

When the parent structure already carries an encoded membership (a
bitfield, an embedded id list) and the full child entities still live
solely in a top-level manager's cache, a sub-manager may **derive** its
`cache` from that encoding instead of filtering or fetching:

```ts
// src/managers/user-badge-manager.ts
export class UserBadgeManager extends BaseManager {
  private user: User;
  public bitfield: number;

  constructor(client: Client, user: User, bitfield: number) {
    super(client);
    this.user = user;
    this.bitfield = bitfield;
  }

  get cache(): Collection<number, Badge> {
    return this.hematite.badges.decode(this.bitfield);
  }
  // No `fetch()` — ensuring the full Badge catalog is loaded is the
  // top-level BadgeManager's job; this sub-manager only projects it.
}
```

This is still not a second source of truth: `bitfield` is mirrored parent
state, and `decode` reads the *top-level* manager's cache to build the
returned `Collection`. Use this only when both hold: the parent's wire
format is genuinely denormalized (not just "there happens to be a scoped
list endpoint"), and full child rows are created/updated exclusively
through the top-level manager.

## Why

The alternative to "one global cache per resource type, everything else is
a view over it" is every scoped collection (a user's invites, a folder's
images) maintaining its own store — and then two different code paths
holding two different `Invite` instances for the same id, one stale. A
sub-manager that's just a filtered view can never drift from the
top-level cache, by construction, because there's nowhere else for the
data to live. `CachedManager`'s `$` helpers exist so "check cache unless
forced, else fetch and merge" isn't reimplemented — slightly differently,
with slightly different bugs — in every manager.

## Exceptions

- A resource with no meaningful cross-referencing from other structures
  (nothing ever needs "get this by id from elsewhere") can sometimes skip
  the full top-level `CachedManager` machinery for a simpler fetch-only
  wrapper — but confirm nothing will need to reference it by id before
  taking that shortcut, since retrofitting a cache later means finding
  every place that fetched it ad hoc.
- Derived-membership sub-managers (`UserBadgeManager`-style) are the one
  sanctioned case where a sub-manager doesn't call `$fetchMany` at all —
  don't generalize "sometimes no fetch method is needed" beyond that
  specific bitfield/encoded-membership shape.

## See also

- [sdk-resolvable-ids](../sdk-resolvable-ids/SKILL.md) — the `resolveId` helper used throughout `CachedManager` and every top-level manager method shown here.
- [sdk-cache-update-placement](../sdk-cache-update-placement/SKILL.md) — where a follow-up update belongs when a mutation needs to touch more than the entity `$editSingle` directly targeted.
- [sdk-naming-conventions](../../conventions/sdk-naming-conventions/SKILL.md) and [sdk-file-section-order](../../conventions/sdk-file-section-order/SKILL.md) — the `$`/`_` and layout rules applied throughout these classes.
