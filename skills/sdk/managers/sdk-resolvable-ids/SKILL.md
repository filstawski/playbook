---
name: sdk-resolvable-ids
description: >-
  The typed "accept an instance or its id" pattern for any method that
  targets one existing entity — a `XResolvable = X | number` type plus a
  single `resolveId(...)` call at the top of the method, so callers can
  pass whichever they already have without the method growing overloads.
  Use when writing a manager/service method that operates on one existing
  entity by id (fetch/edit/delete/"use this one"), or when reviewing a
  method that takes a bare `id: number` and forces every caller to unwrap
  an instance it already had.
metadata:
  type: practice
  category: architecture
---

## Rule

For any method whose job is "do something to one existing entity of type
`X`," accept a resolvable instead of a bare id:

```ts
export type DomainResolvable = Domain | number;

export class DomainManager extends CachedManager<Domain, ApiDomain> {
  public edit(domain: DomainResolvable, data: DomainEditBody): Promise<Domain> {
    const id = this.resolveId(domain);
    return this.$editSingle({
      id,
      data,
      fn: () => this.hematite.$api.domains.$(id).patch({ body: data }),
    });
  }
}
```

`resolveId` itself is one line, defined once on the shared manager base
(see [sdk-manager-layers](../sdk-manager-layers/SKILL.md)):

```ts
public resolveId(structure: Holds | number): number {
  if (structure instanceof this.holds) return structure.id;
  return structure as number;
}
```

Rules of thumb:

- **Define one `XResolvable` type per entity**, next to the other typings
  for that entity (`type DomainResolvable = Domain | number`), not inline
  at each call site — every method targeting a `Domain` reuses the same
  type.
- **Call `resolveId` once, at the top of the method**, then use the plain
  `id` for every API call and cache lookup that follows. Don't scatter
  `instanceof` checks through the method body.
- **Applies to fetch, edit, delete, and similar single-entity entry
  points.** A `create` has no resolvable — there's no existing entity to
  resolve, only a body to send.
- **When the method needs an actual instance after resolving** (not just
  the id), reach for the cache with a materializing fallback —
  `cache.get(id) ?? this.$add({ id })` — rather than typing the parameter
  as the structure class only. That keeps the method accepting id-or-instance
  consistently instead of silently narrowing back to "instance required"
  for the cases that need one.

## Why

A method that only accepts a bare `number` forces every caller who already
holds the instance (the far more common case — most call sites got the
instance from a previous fetch) to go dig the id back out
(`domain.id`) before calling in. A method that only accepts the instance
forces callers who *only* have an id (e.g. from a URL param, a webhook
payload) to fetch first just to get something to pass in. Accepting
`X | number` and resolving once removes both frictions with a single,
reusable line, instead of every method independently deciding which shape
to demand.

## Exceptions

- `create` methods don't take a resolvable — there's no existing entity id
  to resolve.
- A method operating on **many** entities at once (a bulk edit) typically
  takes an array of ids or resolvables and resolves each — the same
  pattern, just mapped, not a reason to skip it.
- If a method never needs to accept a bare id in practice (every realistic
  caller already holds the instance), a plain instance-typed parameter is
  fine — don't add `| number` support nobody will ever pass, just to
  follow the pattern mechanically.

## See also

- [sdk-manager-layers](../sdk-manager-layers/SKILL.md) — where `resolveId` lives and how top-level managers use it end to end.
