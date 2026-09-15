# api / routing

How a file-system-routed API is actually structured: what file a route
belongs in, and how repeated resource-loading/ownership checks get pulled
out of individual handlers.

1. **[api-route-structure](api-route-structure/SKILL.md)** — start here.
   Directory conventions (index-style route files, named action files,
   `[param]` segments, scoped middleware), and the full
   `describe → body → config → response → throws → handle` handler chain
   with worked examples.
2. **[api-route-procedures](api-route-procedures/SKILL.md)** — the
   "resolve a resource and guard it once" building block referenced from
   the skill above. Split out on its own because it's reused from every
   route touching a given resource, not just the index-style ones.

See also [../managers](../managers/README.md) for what a route handler
calls into once it has the guarded resource, and [../stack](../stack/README.md)
for where the global auth/rate-limit defaults a route's `.config({...})`
overrides come from.
