# Interaction

Pointer, keyboard, touch, menus, lists and AI conversations.

## Everything clickable shows the pointer; rows are one target

**MUST** · 2026-09 → 2026-10 · dashboard apps, company website (6 sources)

Set `cursor: pointer` in one base rule for enabled buttons and
`role="button"` (Tailwind 4 resets buttons to the arrow), menu items,
options and palette results. A row that opens something is clickable across
its full width, with hover and press feedback, not only on its title. Make
openable items look openable. Audit with a script that visits each page.

**Why:** the user kept finding menus, tabs, buttons and task rows that
showed the arrow, and found it confusing. A document row gave no sign at all
that it could be opened.

```css
@layer base {
  button:not(:disabled), [role="button"]:not([aria-disabled="true"]),
  [role="menuitem"], [role="option"] { cursor: pointer; }
}
```

## The primary action sits near the hand; destructive actions sit away from it

**SHOULD** · 2026-11 · established UX law

- **Primary action.** It's the largest target and sits where the pointer or
  thumb already is: beside the field or form it submits, and within thumb
  reach at the bottom of the screen on phones.
- **Destructive actions** are never next to Save. They go in the ⋯ menu
  ([quiet records](navigation-and-structure.md#quiet-records)) or at the far
  side, so a slip can't hit them.
- **Destructive confirmations.** Cancel takes the default focus, and the
  destructive button is no larger than Cancel and names the verb ("Delete
  address", not "OK"). Where the user must type a name to confirm, the text
  field takes focus instead.
- **Hit areas** are covered in
  [design-interface-polish](../../skills/design/design-interface-polish/SKILL.md).

**Why:** Fitts's law. The bigger and closer a target, the faster and
surer the hit, and that applies to the wrong target too.

## Buttons keep their size; every action has an icon

**MUST** · 2026-09 → 2026-10 · dashboard apps (4 sources)

Buttons keep their size when the label changes or when busy. Busy swaps the
icon for a spinner. Every acting button carries an icon, and the same action
looks the same everywhere. Decorative icons don't animate.

**Why:** an animated icon on a button looked "ugly" to the user, and buttons
resized when their content changed. The user asked to "work with icons and
keep one UI language".

## One row interaction model across all tables

**MUST** · 2026-08 · dashboard app

Every table uses one of three patterns, built from shared primitives:

1. The row opens a detail page, with a trailing ⋯ menu (Open, Delete).
2. An inert row with only a ⋯ menu (Edit, Delete), for entities edited in a
   sheet.
3. Read-only rows, for logs.

**Why:** "All of the tables have quite different ways to edit or view the
entries … find a reusable solution and modify all tables."

## Clicking an item opens that item

**SHOULD** · 2026-08 · dashboard app

Cards, chips and calendar entries link to the specific item: a detail page,
or an edit sheet opened over the current view with `?item=<id>`. Closing
removes the parameter and restores the exact view (range, date, filters).
Create flows use the same contract (`?create=new`).

**Why:** calendar chips led to the parent record's general page, so users
had to hunt for the task they had clicked.

## Menus fit their content and don't depend on hover alone

**SHOULD** · 2026-10 → 2026-11 · client dashboard app, company website

- **Width.** A dropdown is as wide as its content and at least as wide as
  its trigger; it never clips. Make that the primitive's default.
- **Hover menus.** A submenu opens after about 120 ms of mouse rest
  (passing over doesn't open it). It stays open while the pointer is over
  the trigger or the panel, with a bridge strip over the gap, and closes
  about 220 ms after leaving.
- **Click, tap and keyboard.** Clicking the label still navigates. A
  separate chevron button opens the menu by click, tap or keyboard
  (`aria-expanded`).

**Why:** a user menu was too narrow and clipped its content. The user wanted
a services menu to open on hover as well as on click, and hover alone would
fail touch and keyboard users.

## Long choice lists: groups of seven or fewer, or search first

**SHOULD** · 2026-11 · established UX law

- **Options people weigh against each other** (plans, sort orders, settings,
  onboarding choices): cut the ones few people pick, and keep each group to
  seven or fewer under a heading.
- **Lookups** (a country, a record, a font, the command palette), where
  people already know what they want: open with focus in a search field.
  Search makes the list's length irrelevant.
- **One decision per step** in onboarding.
- **"Recommended"** marks an option only when there's a real
  recommendation behind it.

**Why:** Hick's law. Decision time grows with the number of choices weighed
at once. Grouping turns one long decision into two short ones, and a
lookup isn't a decision at all.

## Keyboard shortcuts never fire while typing

**SHOULD** · 2026-10 · dashboard app

Single-key shortcuts are ignored while focus is in an input, textarea,
select, contenteditable element or textbox role. Guard every handler with
one shared `isTyping(target)` helper.

**Why:** a quick-add field sat on a screen with single-key choice shortcuts,
and typing in it must not trigger them.

## Keep the conventions people know from other products

**SHOULD** · 2026-11 · established UX law

- **Esc** closes the top layer, and only that one.
- **Enter** submits a single-field form.
- **⌘K / Ctrl+K** opens the command palette where there is one.
- **The browser's Back** closes a sheet or viewer that was opened with a
  URL parameter ([clicking an item](#clicking-an-item-opens-that-item)).
- **The logo** links home. The account menu sits top right.
- **Common icons keep their meaning:** a magnifier means search, a gear means
  settings.
- **Links look like links.**

Put the novelty in the content and the craft, not in where things live or
what keys and gestures do. If a convention has to break, keep the
conventional path working too.

**Why:** Jakob's law. People spend most of their time in other products and
bring those habits with them, so a moved convention costs them every time.

## Touch: light what the eye rests on

**SHOULD** · 2026-11 · company website

Hover-only effects never show on phones. Instead, light the card that
crosses an eye line at about 45% of the viewport height, only once
scrolling slows to reading speed and after a short dwell, one card at a
time, so a flick doesn't light every card.

**Why:** the user wanted phones to light cards the way the desktop hover
does, without the pointer. Lighting one card at a time also keeps only one
WebGL effect running on a phone.

## Restructure, don't re-orient

**SHOULD** · 2026-10 · client dashboard app

When asked to make a confusing view clearer, change its structure around
the user's next action. Use few columns that fit without sideways
scrolling, and group items under "what has to happen next". Fold away work
that is waiting on others, with a count. Cards show only what tells items
apart. "It just switched orientation, but I was imagining a structural
change."

## Visualizations are actionable

**SHOULD** · 2026-10 · prototypes

Data-heavy list pages offer task-shaped views (board, timeline, cards)
beside the table, and visualizations can be acted on in place instead of
being read-only views that link to a table.

**Why:** dense tables looked confusing and made the product look like the
tools customers already use. A read-only visual that sends people back to
the tables is "like no change for them".

## Files open in an in-app viewer

**SHOULD** · 2026-10 · dashboard app

Clicking a file opens a viewer over the current view; modifier-click still
opens a tab. Arrow keys, buttons and swipe step through sibling files, and
Escape returns focus to the last file's row. Use the browser's native
players for audio, video and PDF.

**Why:** the user wanted files previewed properly "and not just open their
location".

## Assistants: immediate, quiet, structured

**SHOULD** · 2026-10 · dashboard app

- **Sending.** Show the reply container the moment the user sends.
- **Thinking.** A "thinking…" label with a light band sweeping through it.
  No spinning icon ("it looks horrible and doesn't fit").
- **Steps.** Step labels replace one another, so each is gone before the
  next appears. Words stream in.
- **Asking back.** When the assistant needs input, it ends its turn on a
  card, not prose: single or multiple choice with "other…", confirm (safe
  option first, never auto-committed), a record picker whose options show
  the facts that tell look-alikes apart, a date, short text. "Like Claude or
  Cursor do."
- **Typing over a card.** Typing while a question card is waiting sets the
  card aside instead of breaking the thread.

**Why:** the assistant's replies were "just stuffed into one line", and the
user wanted questions, options and confirmations "nicely displayed in the
UI".

## Generated salutations never guess gender

**SHOULD** · 2026-11 · prototype

Generated letters and replies address people by their full name instead of
guessing Mr or Ms from a first name. When sources disagree about a first
name, use the formal surname-only form and say why.

**Why:** guessing gender or the wrong first name in a customer-facing
message is embarrassing and avoidable. One prospect's sources listed two
different first names.
