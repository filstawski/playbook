---
name: sdk-cache-update-placement
description: >-
  Decision heuristic for where a follow-up cache/derived-state update
  belongs when one client SDK operation needs to change more than just the
  entity it directly fetched or edited — the structure's own local patch,
  the owning top-level manager, or a sub-manager's denormalized counter —
  plus an explicit signal for when to stop improvising and consolidate.
  Use when an SDK mutation needs to update a *different* cached instance
  than the one the API call targeted (parent counts, cross-entity
  consistency), or when reviewing why the same counter gets bumped from
  two different places.
metadata:
  type: practice
  category: architecture
---

## Rule

There is no single rule that "all follow-up cache writes belong on the
structure" — pick the layer that keeps **one obvious place** for the
invariant and avoids a stale cache. In priority order:

1. **API response + manager pipeline, first choice.** If the server
   response already contains the updated entity (or list), merge it
   through the normal manager pipeline (`$editSingle` / `$createSingle` /
   `$fetchSingle` / `$add`) on the top-level manager for that type. This
   is consistent for *every* holder of a cached reference automatically —
   nothing else to update by hand.

2. **`structure.$patch()` / `$update()`, for local deltas about *this*
   instance.** Use when the change is clearly scoped to one instance and
   the data isn't a full server response — e.g. patching an avatar
   locally right after an upload completes, before the next full fetch
   would pick it up anyway. Good for a local delta you don't want to route
   through another manager's public API just to reflect something you
   already know.

3. **One top-level-manager method, when one API call implies updates
   across *multiple* cached types.** If switching a user's domain also
   changes a `uses` counter on two different `Domain` instances, that
   orchestration belongs in one method on the top-level manager (e.g.
   `DomainManager#use`) — not spread across `$update` calls issued from
   whichever sub-manager happened to trigger it.

   ```ts
   async use(domain: Domain): Promise<void> {
     const user = this.hematite.users.me;
     if (!user) throw new Error("User is not logged in");

     const oldDomain = user.domain;
     await user.edit({ domainId: domain.id });

     oldDomain.$update({ uses: oldDomain.uses - 1 });
     domain.$update({ uses: domain.uses + 1 });
   }
   ```

4. **Sub-manager bumping a parent's denormalized field — acceptable short
   term, not long term.** After creating/deleting a child resource (a
   comment, a like), the sub-manager may need to bump `commentCount` /
   `likeCount` on the parent. Fine **as long as only one code path**
   mutates that field. The moment a second entry point changes the same
   count, lift the increment/decrement logic into one shared place (a
   top-level-manager helper) instead of letting two call sites each
   maintain their own copy of "how this counter changes." Prefer a
   refetch, or reading the count straight off an API response that
   already returns the authoritative parent, over hand-incrementing at
   all when either is available.

5. **Cache maintenance with no API call involved** — removing dependent
   rows after a delete (child comments when their parent is deleted)
   belongs in the manager that owns *that* cache, right next to its
   `$deleteSingle` (or equivalent) call, not bolted on somewhere else.

### The escalation signal

Refactor incrementally, not preemptively: when you notice **two** places
performing the same follow-up update on one structure type for the same
event, that's the trigger to consolidate into a single top-level-manager
method (tier 3) — not a sign the whole cache-update approach needs
rethinking. Track concrete instances of this as you find them (see
[docs-migration-status-tracking](../../../docs/docs-migration-status-tracking/SKILL.md)
for the checklist-doc shape that works well for this) rather than fixing
them ad hoc and losing track of which ones you've already caught.

## Why

A rigid single rule ("always update from the structure" or "always update
from the manager") sounds simpler but breaks the first time a mutation's
blast radius doesn't match the layer the rule assigned it to — a
single-instance local patch forced through a manager method is needless
indirection, and a multi-instance orchestration left on a structure method
has nowhere obvious to live without duplicating itself per caller. Picking
the tier by *what the update's blast radius actually is* keeps each kind
of update in the layer that can see the whole invariant, so there's
exactly one place per invariant, not per call site.

## Exceptions

- When the server can return the authoritative post-mutation value for
  everything affected (not just the primary entity), always prefer that
  over any hand-computed local delta, at any tier — a real value from the
  server can't drift from truth the way a `+1`/`-1` can.
- Tier 4's "acceptable short term" is a deliberate, time-boxed exception,
  not a default — don't add a *third* denormalized-counter bump from a
  sub-manager and call it consistent with this guideline; that's exactly
  the escalation signal above.

## See also

- [sdk-manager-layers](../sdk-manager-layers/SKILL.md) — the structure/manager/sub-manager roles this heuristic picks between.
- [docs-migration-status-tracking](../../../docs/docs-migration-status-tracking/SKILL.md) — the checklist-doc shape for tracking escalation candidates you've spotted but not yet consolidated.
