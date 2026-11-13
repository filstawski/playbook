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

## Actions that almost never fail show their result at once

**SHOULD** · 2026-11 · established UX law

Toggles, stars, reordering, mark as read and moving a card to another stage
change on the same frame as the click. If the server refuses, roll back and
say so (`useOptimistic`, or a TanStack Query mutation's `onMutate`/`onError`).
Final submits still wait for the server, with the busy state above: paying,
sending something to a client, creating what other people will see.

**Why:** the Doherty threshold. People stay in flow when the interface
answers within about 400 ms, and an action that waits for a round trip it
almost never needs feels slow. The user's own "quick actions happen at
once" rule below is the same idea for dialogs.

## Show what was there last time, never a default that flips

**SHOULD** · 2026-11 · established UX law

While data loads, show what the person saw last time, from the query cache,
and update it when the answer lands. When nothing is cached, show a skeleton
the size of the content ([website-motion P9](../../skills/website/website-motion/patterns.md#p9-skeleton--loading--content-crossfade)).
Never render a default state that the fetch then overturns: an empty star
that fills, a "0" that becomes 12, "Nothing here yet" that becomes a list.

**Why:** the Doherty threshold again. A flipped default reads as the
product changing its mind, and the first state people see is the one they
act on.

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

## End every flow on what happened; fix the worst moment first

**SHOULD** · 2026-11 · established UX law

- **The ending.** Every flow (sign-up, checkout, an import, a multi-step
  form) ends on a confirmation that says what happened and what comes next,
  never on a bare redirect.
- **Celebration.** Save it for real milestones, such as a first success or
  a finished setup ([website-motion P16](../../skills/website/website-motion/patterns.md#p16-progress-in-beats-drawn-checks-arrival-choreography)).
  Routine completions get the quiet confirmation above.
- **Polish order.** When choosing what to polish, fix the worst moment (an
  error, a long wait, a dead end) before improving an average one.

**Why:** the peak-end rule. People judge an experience by its most intense
moment and by its end, and those two are what they remember and tell others
about.

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

## Reversible actions get Undo, not a confirmation

**SHOULD** · 2026-11 · established UX law

Archiving, removing from a list, marking done and moving one item happen at
once, with no dialog in front. A toast offers Undo for 8 seconds. The request
goes out when the toast closes without Undo, or when the page is hidden, so
Undo only has to put the item back
([website-motion P15](../../skills/website/website-motion/patterns.md#p15-toasts)).
Keep confirmation dialogs for what can't be undone, and for actions that
take other records with them. Those follow the next entry.

**Why:** people click through confirmation dialogs by habit, so a
confirmation prevents little, while Undo still works after the mistake.
Where the two disagree, the user's own rule below wins: a trash
confirmation that names what goes along with it stays.

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

## Sound stays unbuilt until asked

**CONSIDER** · 2026-10 · dashboard app

A sound concept exists: few sounds, only for things that arrive while you
work and for wins; never for clicks, hovers, typing, saves or errors; short,
quiet and generated with the Web Audio API. Don't build it until the user
asks.

**Why:** the user asked for it to be written down ("let's write it down for
now"), and on 2026-11-03 decided to keep it unbuilt.
