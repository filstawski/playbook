# api

My default approach to building a TypeScript backend API: which stack to
reach for, how routes are laid out on disk, and how business logic is
structured so CRUD boilerplate doesn't get hand-rolled per model.

Three subfolders, roughly in the order you'd hit them building something
new:

| Folder | Covers | Skills |
| --- | --- | --- |
| [stack](stack/README.md) | Framework + library choices | `api-framework-stack`, `api-default-libraries` |
| [routing](routing/README.md) | File-based route layout + resource guards | `api-route-structure`, `api-route-procedures` |
| [managers](managers/README.md) | The business-logic layer routes call into | `api-manager-base`, `api-manager-declarative-config`, `api-manager-effects-and-populators` |

## Reading order

**Bootstrapping a new API from scratch:** `stack` → `routing` → `managers`,
in that order — each layer's skills reference the ones below them.

**Already have an API, adding a feature to it:** skip straight to whichever
subfolder answers the question at hand. Adding an endpoint → `routing`.
Adding a model with real CRUD and side-effects → `managers`. Picking a
library for a new capability (email, payments, file storage) → `stack`.

**Debugging "why isn't X happening":** almost always
[api-manager-effects-and-populators](managers/api-manager-effects-and-populators/SKILL.md)
(missing/misconfigured realtime or audit wiring) or
[api-manager-declarative-config](managers/api-manager-declarative-config/SKILL.md)
(a delete/cascade case the declared config doesn't cover).

## Why this is organized as a domain, not flat

Everything under `skills/api/` shares vocabulary and cross-references each
other constantly (a route calls a manager, a manager's `StorageUpload`
comes from the stack). Grouping by domain here keeps that web of
references shallow and makes the reading order legible. This doesn't
change how a skill gets *used* — reuse in another project still means
symlinking one leaf skill directory (e.g. `api-manager-base/`) into
`~/.claude/skills/api-manager-base` or a project's `.claude/skills/`; where
it happens to live inside this repo is irrelevant to that. See the root
[CONCEPT.md](../../CONCEPT.md) for the full reasoning.

A future non-API domain (say, `skills/git/` or `skills/testing/`) gets its
own top-level folder and its own `README.md` following this same shape —
nothing here is API-specific about the *pattern*, only its contents are.
