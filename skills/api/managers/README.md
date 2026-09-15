# api / managers

The declarative domain-manager pattern: one generic base class plus
per-model configuration, replacing hand-written CRUD classes that
duplicate side-effects (storage, realtime, audit, cascading deletes) across
every model.

Split into three skills because each is independently useful — "what does
the base class actually do," "what do I declare on a subclass," and "how
do the effects/populators underneath actually work" are three different
questions with three different answers — but they're meant to be read
together the first time:

1. **[api-manager-base](api-manager-base/SKILL.md)** — start here. The
   generic `BaseManager` class in full, plus a simple manager and a
   file-upload manager built on it. Establishes the vocabulary
   (`find`/`fetch`, `finishCreate`, `owns`, `deleteFlow`) the other two
   skills assume.
2. **[api-manager-declarative-config](api-manager-declarative-config/SKILL.md)**
   — the config types a concrete manager fills in: `resource`, `shareable`,
   `userDelta`, `owns`, `deleteFlow`. Two full worked managers (a
   cascade-delete model, a custom-delete-flow model).
3. **[api-manager-effects-and-populators](api-manager-effects-and-populators/SKILL.md)**
   — the machinery underneath: deferred `Effect`s (socket/audit/CDN,
   fired via `Promise.allSettled`) and composable, batched `Populator`s
   (including the data-driven polymorphic feature table).

Reach for one directly once you know which question you have — e.g.
"why isn't my realtime event firing" is almost always answered in
`api-manager-effects-and-populators`, "how do I stop a delete from
cascading and reassign rows instead" in `api-manager-declarative-config`.

See also [../routing](../routing/README.md) for the layer that calls into
these managers, and [../stack](../stack/README.md) for the ORM/storage
choices they're built on.
