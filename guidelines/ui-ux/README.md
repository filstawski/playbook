# 1. UI/UX

How the interface behaves for the people using it: motion feel, feedback,
empty and locked states, forms, interaction, navigation.

| File | Covers |
| --- | --- |
| [motion.md](motion.md) | the motion rules every agent must know; the full system is the [website-motion](../../skills/website/website-motion/SKILL.md) skill |
| [feedback-and-states.md](feedback-and-states.md) | busy, optimistic updates, cached reads, progress, created, flow endings, empty, locked, permission, undo vs confirm, layout stability, first paint |
| [forms.md](forms.md) | error placement, validation timing, the error shake, placeholders, required fields, validators, lookups, natural-language dates, AI-filled fields, lenient formats, chunking, defaults, multi-step progress, follow-up fields |
| [interaction.md](interaction.md) | pointer and hit targets, where primary and destructive actions go, buttons, tables, deep links, menus, long choice lists, shortcuts, conventions, touch, viewers, assistants |
| [navigation-and-structure.md](navigation-and-structure.md) | breadcrumbs, areas and tabs, entry points, overview pages, quiet records, one job per page |

## Know these first

- **Nothing teleports.** Every appear, disappear, resize and swap animates,
  fixed in the shared primitive.
- **A correction on one page applies to every page of its kind.**
- **An error marks only its own field.** Server and network errors go above
  the buttons.
- **Every slow action shows busy feedback at once**, and buttons keep their
  size.
- **Everything clickable shows the pointer**, and rows are clickable edge to
  edge.
- **Breadcrumbs start with a section,** never with a record's name.

Related: [design-guidelines](../design-guidelines/README.md) for the visual
side, and [design-interface-polish](../../skills/design/design-interface-polish/SKILL.md)
for the detail pass.
