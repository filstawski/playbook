# sdk

My default approach to building a client SDK/library that wraps a typed
HTTP API: what to build it on, how to layer structures/managers, and the
naming and layout conventions that keep dozens of near-identical resource
files actually consistent.

Three subfolders, mirroring [../api](../api/README.md)'s shape:

| Folder | Covers | Skills |
| --- | --- | --- |
| [stack](stack/README.md) | Framework + library choices | `sdk-client-stack` |
| [managers](managers/README.md) | The structure/manager/sub-manager architecture | `sdk-manager-layers`, `sdk-resolvable-ids`, `sdk-cache-update-placement` |
| [conventions](conventions/README.md) | Naming, visibility, file layout | `sdk-naming-conventions`, `sdk-file-section-order` |

## Reading order

**Building a new SDK from scratch:** `stack` → `managers` → `conventions`.

**Adding a resource to an existing SDK:** `managers` (start with
`sdk-manager-layers`) for the structure/manager/sub-manager shape, then
`conventions` for how the new files should actually look.

**"Where does this cache update go" / "why is there a stale copy of X
somewhere":** [sdk-cache-update-placement](managers/sdk-cache-update-placement/SKILL.md)
almost always has the answer.

## Relationship to `api/`

An SDK in this shape is generated *against* an API in the
[api](../api/README.md) shape — `sdk-client-stack`'s low-level client is
produced from the server's own schema-first routes
([api-framework-stack](../api/stack/api-framework-stack/SKILL.md)), and
`sdk-resolvable-ids` is the client-side mirror of a pattern the API side
was still only considering when its own manager skills were written. The
two domains are meant to be read together when a project has both a
server and a first-party SDK for it.
