# sdk / stack

The default technology choices for a client SDK wrapping a typed HTTP API.

- **[sdk-client-stack](sdk-client-stack/SKILL.md)** — generated low-level
  API client, `Collection` as the cache primitive, realtime as a socket
  client (not server), typed SDK-level events over the raw transport.

See also [../managers](../managers/README.md) for how the generated client
and the cache actually get composed into structures and managers, and
[../../api/stack](../../api/stack/README.md) for the server side this
client is generated against.
