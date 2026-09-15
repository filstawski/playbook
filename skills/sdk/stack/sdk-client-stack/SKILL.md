---
name: sdk-client-stack
description: >-
  Default stack for a TypeScript client SDK wrapping a typed HTTP API — a
  generated low-level API client (from the same schema-first framework the
  server uses), a Map-based Collection as the caching primitive, and
  realtime via a socket client rather than hosting a server. Use when
  scaffolding a new SDK/client-library package, deciding how to keep a
  generated API client in sync with the server, or choosing a cache data
  structure for in-memory entity storage.
metadata:
  type: practice
  category: tooling
---

## Rule

- **Generate the low-level HTTP client from the server's own schema,
  don't hand-write it.** If the server is built on a schema-first
  framework (routes carry Zod/typed contracts — see
  [api-framework-stack](../../../api/stack/api-framework-stack/SKILL.md)),
  that framework's client-generation tooling can produce a fully-typed
  request client directly from a running server:

  ```json
  // package.json
  {
    "scripts": {
      "api:generate": "pumice generate --url http://localhost:3000 --output ./src/generated/api.ts --debug"
    }
  }
  ```

  The generated file is checked in (or regenerated as a build step) and
  becomes the SDK's only source of HTTP request/response types — nobody
  hand-maintains a parallel set of request/response interfaces that can
  drift from the actual API.
- **Expose the generated client as one low-level escape hatch, everything
  else wraps it.** Give it an internal-only name (see
  [sdk-naming-conventions](../../conventions/sdk-naming-conventions/SKILL.md)
  for the `$`-prefix convention) so consumers reach for the high-level
  manager API by default and only drop to the raw client for something
  genuinely uncovered.
- **Use a `Map`-subclass `Collection` as the cache primitive**, not a plain
  object or a hand-rolled cache class. `@discordjs/collection` (or
  equivalent) gives array-like methods (`filter`, `find`, `map`) directly
  on a keyed store, which is exactly the shape a "cache of entities by id"
  needs — a plain `Map` doesn't have them, and a plain object loses
  numeric/typed keys and `Map`'s iteration guarantees.
- **Realtime is a client, not a server, inside the SDK.** The SDK connects
  outward to the API's realtime layer (`socket.io-client`, or raw `ws` for
  a lower-level transport) — it never hosts a socket server itself. This
  mirrors the API-side default (see
  [api-framework-stack](../../../api/stack/api-framework-stack/SKILL.md))
  of treating realtime as something connected to, not owned, unless the
  process genuinely is the realtime server.
- **A typed event emitter for SDK-level events**, separate from the raw
  socket transport — the SDK translates raw socket payloads into typed,
  documented SDK events (`image:create`, `user:update`, ...) that
  consumers subscribe to, rather than handing consumers the raw socket
  connection to parse themselves.

## Why

Hand-maintaining a second copy of every request/response type that the
server framework already generates from its own route definitions
guarantees drift the first time someone changes a route and forgets the
SDK — codegen from the live server (or its schema) removes an entire class
of "the SDK is now wrong" bugs by construction. A `Map`-based collection
as the cache primitive isn't a style preference: every manager in the SDK
needs the same operations (get by id, filter to a subset, iterate) on the
same cache, and a type that already has those methods means managers
don't each reinvent filtering.

## Exceptions

- For a very small SDK wrapping a handful of endpoints, generating a
  client from a framework may be overkill — hand-writing a thin fetch
  wrapper is fine when there's no meaningful schema to generate from in
  the first place.
- A `Collection`/`Map`-based cache assumes numeric or string entity ids.
  For an API with composite keys, a different cache key strategy is
  needed — don't force composite identity through a single-value `Map`
  key without a clear serialization scheme.

## See also

- [sdk-manager-layers](../../managers/sdk-manager-layers/SKILL.md) — how the generated client and the `Collection` cache come together into structures/managers/sub-managers.
- [sdk-naming-conventions](../../conventions/sdk-naming-conventions/SKILL.md) — why the generated client is exposed `$`-prefixed rather than as a plain public property.
