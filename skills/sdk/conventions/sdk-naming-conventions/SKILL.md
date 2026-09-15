---
name: sdk-naming-conventions
description: >-
  Naming and visibility conventions for a client SDK's public surface —
  what a leading `_` versus `$` on a member signals, strict default
  visibility (nothing public by default), boolean/predicate naming, and
  never marking a method `async` when it only forwards another promise.
  Use when adding a new method or property to an SDK class and deciding
  its name, visibility, or whether to mark it `async`, or when reviewing
  whether an SDK's public surface has grown wider than intended.
metadata:
  type: practice
  category: architecture
---

## Rule

- **Strict access modifiers by default.** Default to `protected` or
  private; mark something `public` only when consumers genuinely need it.
  Expose as few methods as possible — ship polished, intentional APIs, not
  everything that happened to be convenient to implement as a method.
- **Managers expose as few fetch entry points as practical.** Prefer one
  smart `fetch` (using overloads or an optional first argument to cover
  single/many/filtered cases) over several similarly-named fetch variants.
  Add a genuinely distinct method (`search`, `discover`) only when the API
  shape is actually different, not as a naming convenience.
- **Leading underscore (`_`) = temporary, incomplete, or "needs a proper
  implementation."** Treat anything `_`-prefixed as not ready for casual
  use — it's a marker that the surface may still change shape.
- **Leading dollar (`$`) = internal and undocumented.** A `$`-prefixed
  member is glue that a higher-level wrapper exists for; callers should
  use the wrapper, and a `$` member is never part of the documented public
  contract even if it's technically reachable.
- **Boolean/predicate-style members read as "this is ..."** and get a
  matching prefix — `is`, `isNot`, `in`, etc. (`isPartial`, `inGracePeriod`)
  — not a bare adjective or an ambiguous verb.
- **Never mark a method `async` when it only returns another call's
  promise directly.** If a method's entire body is
  `return this.other.thing(...)`, drop `async` and return that promise —
  reserve `async`/`await` for methods that actually need control flow
  around the awaited result (error shaping, combining multiple calls,
  post-processing).

  ```ts
  // Wrong — async adds nothing here.
  async fetch(id: number): Promise<Domain> {
    return this.hematite.domains.fetch(id);
  }

  // Right.
  fetch(id: number): Promise<Domain> {
    return this.hematite.domains.fetch(id);
  }
  ```
- **Scope stays tight to the API/client domain.** Don't let framework- or
  platform-specific concerns (a UI framework's re-render helpers, a
  particular bundler's conventions) leak into the SDK — a client library
  should be usable from any consumer, not coupled to how one particular
  frontend happens to use it.

## Why

A wide, casually-`public` surface is a permanent commitment the moment
someone starts depending on it — every `public` member is something a
future version can't quietly remove without a breaking-change bump. `_`
and `$` exist so "this looks callable" and "this is safe to build on" can
be told apart at a glance, without needing to check the docs or the
implementation first — a consumer reading autocomplete sees the signal
directly in the member name. Dropping unnecessary `async` isn't just
style: an `async` wrapper around a passthrough call adds an extra
microtask tick and turns a synchronous throw into a rejected promise one
layer later than it needs to, which occasionally matters for callers doing
their own error-flow control.

## Exceptions

- A `_`-prefixed member that's been stable for a long time and has several
  real callers has effectively become part of the contract whether or not
  it's documented — that's a sign to either promote it (rename, document,
  make it genuinely public) or actively deprecate it, not to leave it
  indefinitely in an ambiguous "temporary" state.
- `async` is fine to keep on a passthrough method if the surrounding class
  consistently uses `async`/`await` for readability reasons and the
  performance difference is genuinely immaterial for that call path — this
  is a default, not an absolute; don't chase removing `async` from a
  passthrough as an isolated refactor with no other changes nearby.

## See also

- [sdk-manager-layers](../../managers/sdk-manager-layers/SKILL.md) — where `$`/`_`-prefixed members actually show up (`$fetchSingle`, `$add`, `resolveId`).
- [sdk-file-section-order](../sdk-file-section-order/SKILL.md) — the companion layout convention for the same files these naming rules apply to.
