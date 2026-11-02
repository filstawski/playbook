# 6. APIs

Interfaces between systems and toward agents: contracts, inbound endpoints,
links that act, command-line interfaces, and AI features inside apps. Route
and handler structure for a TypeScript API is in the
[api skills](../../skills/api/README.md).

| File | Covers |
| --- | --- |
| [design.md](design.md) | append-only contracts and error shape, inbound endpoints from sibling apps, safe sign-in redirects, email links that don't act on GET, external file sharing, CLI design |
| [ai-features.md](ai-features.md) | the model proposes and the user approves, memory in records, MCP through the app, data-processing to-dos |

## Know these first

- **Never rename fields, error codes or exit codes;** add new ones.
- **Links in emails never change state on GET.**
- **Embedded AI never writes without a person's approval,** and runs tools
  as the asking user.
- **CLIs prompt at a terminal and stay stable for scripts** (`--json`, exit
  codes).
