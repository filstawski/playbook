# Feedback and states

What the interface shows while something happens, when nothing is there,
and when something can't be done.

## Nothing teleports

The first rule of feedback is in [motion.md](motion.md#nothing-teleports):
errors, size changes and new content animate in, fixed in the shared
primitive.

## Every slow action shows busy feedback at once

**MUST** · 2026-10 · dashboard apps (4 sources)

A button that starts slow work swaps its icon for a spinner, looks
disabled, keeps its size and focus, and shows a clear retry message if it
fails. Downloads fetch the file to a blob and stay busy until the file
arrives ("the ZIP download button just does nothing for a few seconds").
Inline autosave fields show a spinner while saving, then a check that fades
out, announced to screen readers.

## Long tasks show phases, never a fake percentage

**SHOULD** · 2026-08 · dashboard app

Multi-step background tasks show a phase stepper (done, active, upcoming),
a header line with the current detail, and live counters (processed,
skipped, elapsed). Show a percentage only when the total is known; otherwise
use an indeterminate shimmer. One progress component for every task.
Results stay on screen until dismissed.

**Why:** an earlier export bar always showed 100% and told the user nothing.
The user liked the phased redesign, then asked that results not vanish the
moment a task ends.

## After creating something, say where it went

**SHOULD** · 2026-10 · dashboard app

When a create sheet closes, confirm briefly where the item landed ("created,
due tomorrow", "no date: under All"). Default fields like the date to the
view it was created from, so the new item doesn't seem to vanish.

## Quick actions happen at once; extras come after

**SHOULD** · 2026-11 · dashboard app

Never put a dialog in front of a fast action, such as moving an item to
another stage. Do the action at once. After the server confirms it, raise a
small bar at the bottom offering the optional extra (a note), saved with
Enter and dismissed with Escape. Nothing moves under the pointer. For
frequent small edits (a next step, a due date), use inline fields with
suggestions, quick-date chips and undo instead of dialogs.

**Why:** an earlier version put a dialog in front of moving to the next
stage, and the user found it slow: "I just feel like the UX isn't good."

## No blank pages

**SHOULD** · 2026-09 → 2026-11 · dashboard apps, company website (4 sources)

A page or tab with nothing to show explains why (before or after the data
can exist) and offers the way forward. A thin page uses its space like its
sibling tabs. Prefer one list over several sections that might each be
empty. Show a type filter only once more than one kind exists. Zero reads
naturally ("no item uses it yet", not "0 items use it"). On public sites, an
empty state can preview what will be there.

**Why:** a documents tab was "just void" once its record was closed, and a
mostly empty activity page looked "ugly" to the user.

## Locked controls look locked

**MUST** · 2026-10 · dashboard app

A disabled or read-only control loses the brand color, drops hover feedback
and the pointer cursor, and shows a lock icon with the reason where the page
knows it. Fix this in the shared component; with Base UI, style
`data-disabled` and `data-readonly`.

**Why:** "Currently it's just unclickable but still looks like a normal
checkbox."

## The UI hides; the server decides; pages say why

**SHOULD** · 2026-08 → 2026-10 · dashboard apps

- Leave out controls a role can't use.
- Where the action is the page's whole point (an upload tab), say who can do
  it.
- Show items the role can't open as locked, with the permission they need.
- Render links to pages the role can't open as plain text.
- A page the viewer may not open shows an explicit "no permission" state,
  not a silent redirect.

**Why:** users without a permission were silently sent back to the home page
and didn't understand why ("Please add proper states").

## Confirmations state consequences

**SHOULD** · 2026-08 → 2026-10 · dashboard apps

A delete or trash confirmation says what goes along with it ("with 3 people
and one item"). When something blocks the action, the dialog says why and
disables the button. Permanently deleting something high-stakes asks the
user to type its name. Replace native `confirm()` with one themed,
promise-based confirmation dialog.

## Layout never shifts on state changes

**SHOULD** · 2026-10 · dashboard app

An alternative view of a record (archived, trashed) keeps the same width and
header layout, so nothing jumps when it switches. A horizontally
overflowing row of chips gets an edge fade at every width, never a hard cut.
Glows, halos and focus rings are never cut off by overflow or masks.

**Why:** a submit button's glow was cut off by an animating box, and logo
hover glows were cropped by a row mask: "It looks horrible and the glows are
cut off."

## The first paint is already right

**MUST** · 2026-10 → 2026-11 · company website, client sites

Nothing above the fold waits for a script, and heavy visual effects are
there from the first frame rather than fading or pouring in late. See
[../frontend/websites.md](../frontend/websites.md).

**Why:** a hero graphic appeared about a second after the page and shader
effects faded in late, which the user called ugly. The fix was asked for
"not just there, but generally".
