# sdk / managers

The three-layer client architecture (structure / top-level manager /
sub-manager) and the decisions that come up building on it.

1. **[sdk-manager-layers](sdk-manager-layers/SKILL.md)** — start here. The
   `Base`, `CachedManager`, and `BaseManager` classes in full, plus a
   top-level manager, a filtered sub-manager, and a derived-membership
   sub-manager example.
2. **[sdk-resolvable-ids](sdk-resolvable-ids/SKILL.md)** — the `X | number`
   + `resolveId` pattern every single-entity manager method uses.
3. **[sdk-cache-update-placement](sdk-cache-update-placement/SKILL.md)** —
   which layer a follow-up cache update belongs on when one mutation
   affects more than the entity it directly targeted.

See also [../stack](../stack/README.md) for what these managers are built
on, and [../conventions](../conventions/README.md) for the naming/layout
rules applied inside every file here.
