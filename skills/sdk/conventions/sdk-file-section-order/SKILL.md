---
name: sdk-file-section-order
description: >-
  A fixed, numbered section order enforced on every structure and manager
  file in a client SDK, with empty slots marked rather than omitted, so any
  file is navigable by position alone regardless of size. Use when creating
  a new structure or manager class, when reviewing whether a file follows
  the house layout, or when deciding where a new method belongs within an
  existing file.
metadata:
  type: practice
  category: architecture
---

## Rule

Every file of a given kind uses the same section order, marked with
numbered comments. An empty section still gets a one-line marker — it is
never silently omitted — so a reader (or a diff) can trust that "section 6
is missing" means "nothing belongs there," not "forgotten."

### Structures

```ts
export class User extends Base {
  /* 01 - Sub-Managers */
  public invites = new UserInviteManager(this.hematite, this);

  /* 02 - Constructor */
  constructor(client: Client, data: PartialStructure<ApiUser>) {
    super(client, data.id);
    this.$patch(data);
  }

  /* 03 - $patch method override */
  public $patch(data: Partial<ApiUser>): void {
    super.$patch(data);
    // attach sub-structures that depend on payload fields, e.g. badges
  }

  /* 04 - Partial getter */
  public get partial(): boolean {
    return false;
  }

  /* 05 - Additional getters */

  /* 06 - Fetch methods */
  public fetch(): Promise<User> {
    return this.hematite.users.fetch(this);
  }

  /* 07 - Additional fetching methods */

  /* 08 - Edit methods */
  public edit(data: UserEditBody): Promise<User> {
    return this.hematite.users.edit(this, data);
  }

  /* 09 - Additional editing/modify methods */

  /* 10 - Delete methods */

  /* 11 - Additional delete methods */

  /* 12 - Additional methods */

  /* 13 - Internal / `_` helpers methods */
}
```

Combine adjacent empty ranges on small types instead of stacking many
one-line markers: `/* 06–09 — none */`.

### Top-level managers

```ts
export class DomainManager extends CachedManager<Domain, ApiDomain> {
  /* 01 - Constructor */
  constructor(client: Client) {
    super(client, Domain);
  }

  /* 02 - Special getters */
  // e.g. `get me()`, small derived views over `cache`, no I/O.

  /* 03 - Fetch */
  public fetch(domain: DomainResolvable): Promise<Domain> { /* ... */ }

  /* 04 - Additional fetch paths */

  /* 05 - Create */
  public create(data: DomainCreateBody): Promise<Domain> { /* ... */ }

  /* 06 - Additional create methods */

  /* 07 - Edit */
  public edit(domain: DomainResolvable, data: DomainEditBody): Promise<Domain> { /* ... */ }

  /* 08 - Additional edit methods */

  /* 09 - Delete */

  /* 10 - Additional delete methods */

  /* 11 - Additional methods */
  // auth helpers, `use`, `fromReference`, etc. — anything beyond a fetch overload.

  /* 12 - Internal / helpers */
}
```

### Sub-managers

```ts
export class UserInviteManager extends BaseManager {
  /* 01 - Parent structure */
  private user: User;

  /* 02 - Constructor */
  constructor(client: Client, user: User) {
    super(client);
    this.user = user;
  }

  /* 03 - Cache */
  get cache(): Collection<number, Invite> {
    return this.hematite.invites.cache.filter((i) => i.userId === this.user.id);
  }

  /* 04 - Primary fetch */
  fetch(): Promise<Collection<number, Invite>> { /* ... */ }

  /* 05 - Other scoped operations */

  /* 06 - Internal / `_` helpers */
}
```

Rules of thumb:

- The numbering (and its meaning) is **fixed per file kind** — a structure
  file, a top-level manager file, and a sub-manager file each have their
  own numbered order, applied consistently across every file of that kind.
- A tiny type still gets the full numbering with empty markers — the
  convention is "every file is navigable at the same coordinates," which
  breaks the moment even one file skips numbering because it seemed too
  small to bother.
- When rolling this convention out to an existing codebase, do it file by
  file and track which files still need it (see
  [docs-migration-status-tracking](../../../docs/docs-migration-status-tracking/SKILL.md))
  rather than treating "some files have it, some don't" as good enough
  indefinitely.

## Why

Once every file of a kind shares the same section order, "where does this
new method go" stops being a judgment call and "where is the delete logic
for this structure" stops requiring a file-wide read — the answer is
always at the same numbered position. That consistency is worth more than
any individual ordering choice being locally optimal; the value is in
every file being predictable, not in this specific order being the best
possible one. Marking empty sections (instead of omitting them) preserves
that predictability for files that don't need every section yet.

## Exceptions

- A file kind not covered by an existing numbered order (a new architectural
  layer introduced later) needs its own order defined once, not forced
  into an existing numbering that doesn't fit its actual concerns.
- Don't retrofit numbering onto a file mid-unrelated-change — track it (per
  the migration-status-tracking pattern) and do the reformat as its own
  pass, so a diff either does the rename/reorder or the logic change, not
  both tangled together.

## See also

- [sdk-naming-conventions](../sdk-naming-conventions/SKILL.md) — the companion `$`/`_`/visibility rules for the same files.
- [sdk-manager-layers](../../managers/sdk-manager-layers/SKILL.md) — the structure/manager/sub-manager roles this section order is defined per.
- [docs-migration-status-tracking](../../../docs/docs-migration-status-tracking/SKILL.md) — how to track a partial rollout of this convention across an existing codebase.
