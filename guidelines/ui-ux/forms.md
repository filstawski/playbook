# Forms

How forms behave for the person filling them in. The implementation
(react-hook-form, Zod, server errors) is in
[../frontend/nextjs-and-react.md](../frontend/nextjs-and-react.md#forms)
and [website-nextjs-dashboard-forms](../../skills/website/nextjs/website-nextjs-dashboard-forms/SKILL.md).

## An error marks only its own field, and shows once

**MUST** · 2026-09 → 2026-10 · dashboard apps (4 sources)

Only a wrong value marks its field invalid. Server errors, lost
connections, rate limits and lockouts show as one form-level message above
the submit buttons and leave the fields alone. An error placed on a field is
not also toasted. An empty submit names every missing field at once:
cross-field rules still run when another field fails.

**Why:** "The password field gets invalid even if it's an error 500 and has
nothing to do with the password."

## Check a field when it's left, then live once it's wrong

**SHOULD** · 2026-11 · every form (decided 2026-11-13)

Never mark a field wrong while someone is still typing it for the first
time. Check it when they leave it (or on submit). Once it shows an error,
re-check it on every keystroke, so the error clears the moment it's fixed.
In react-hook-form: `mode: "onTouched"`, `reValidateMode: "onChange"`
([website-nextjs-dashboard-forms](../../skills/website/nextjs/website-nextjs-dashboard-forms/SKILL.md)).

**Why:** Postel's law (an established UX law) and the user's decision on
2026-11-13. With checks on every keystroke from the start, a half-typed email
showed "invalid" after its first letter.

**Changed:** forms used `mode: "onChange"` until 2026-11-13.

## A failed submit shakes the wrong fields, slightly

**SHOULD** · 2026-11 · every form (decided 2026-11-13)

When a submit fails the browser-side check, each wrong field shakes once,
a few pixels, as well as getting its red rim and message, and focus moves to
the first wrong field. Nothing shakes on blur, while typing, or for a server
or network error (that message goes above the buttons). Under reduced
motion nothing shakes. Code: [website-motion P2](../../skills/website/website-motion/patterns.md#p2-heightwidth-auto-collapse-animatedimensions-fielderror).

**Why:** the user decided "yes, shake it slightly" on 2026-11-13. The
movement shows where the problem is in a long form, and kept small it reads
as a nudge rather than a scolding.

## Every input has a bare example placeholder

**MUST** · 2026-09 → 2026-10 · dashboard apps (6 sources)

Every input and textarea gets a placeholder showing a real-looking example
value in the UI language, with no "e.g." prefix ("Always add placeholders to
inputs!"). A select shows the action instead ("Select an object" / "Objekt
auswählen").

**Why:** a field without an example leaves people guessing the format;
"e.g." was dropped as noise.

**Changed:** earlier placeholders were written as "z. B. …"; the current
rule is the bare example.

## Require only what the step needs; mark required, not optional

**SHOULD** · 2026-09 → 2026-10 · dashboard apps (4 sources)

Don't make a field required unless the step can't work without it. Labels,
notes and "who is this for" fields only help the creator recognize
something later, so they are optional, with a hint saying so and a
generated fallback name ("Link from 3 Nov"). Mark required fields with an
asterisk and `aria-required`, never "optional" ones, and only in forms where
few fields are required.

**Why:** the user found a link form too strict: "I want to be able to send
links to anyone or even to my other PC."

## Formatted fields share one strict validator set

**MUST** · 2026-10 · dashboard app

A field with a recognizable format uses one shared set of validators, on
client and server, never a length check alone:

- phone numbers checked against a full numbering-plan dataset
- postal codes with the exact digit count (input capped)
- city names in letters only
- URLs that actually parse

**Why:** "for the phone number or zip code we can enter anything, and the
website field accepts 'abc'."

## Re-validate a dependent field when its condition changes

**MUST** · 2026-09 · client dashboard app

When a field's validity depends on another value (an attached file, a
checkbox), re-run that field's validation whenever the condition changes,
but only after the first submit attempt, like typing would. In
react-hook-form, `setValue` doesn't revalidate other fields; call
`trigger("field")`.

**Why:** a stale "email required" error stayed on screen after the user had
provided the alternative upload, which made for "weird UX".

## Don't send the user elsewhere; finish the action in place

**SHOULD** · 2026-10 · dashboard app

When an action can't complete because data is missing, don't show a message
telling the user to go fix it on another page. Open the existing form in a
side sheet, prefilled with everything known, focus the missing field, and
complete the action from there ("give us some kind of dialog … instead of
breaking our flow").

## Lookups fill only empty fields and say what they did

**SHOULD** · 2026-10 · dashboard app

When a value triggers a lookup that can fill other fields (a website, a
postal code), fill only the fields the user left empty, never overwrite
typed input, and take grouped values (an address) only as a whole. Show one
line under the trigger field saying what was filled, or why nothing was.

**Why:** it keeps the user in control of what they typed. The pattern worked
well on a create form that reads a website to fill in missing fields.

## Accept natural language for dates and schedules

**SHOULD** · 2026-10 · dashboard app

Where users set reminders, dates or recurrence, accept free text in the UI
language alongside presets. Preview how the input was read, accept on Enter,
and when unsure add nothing and say so with examples. Watch for date parsers
that mix languages: a local word for "tomorrow" was read as English
"morning".

**Why:** the user wanted to "use natural language … and not just the
preselected ones" when setting schedules.

## Dialogs open focused and fresh

**SHOULD** · 2026-09 → 2026-10 · dashboard apps

A form dialog opens with focus on its first text field, not on a close
button, and starts fresh each time. Replace native date inputs, datalists
and raw hex fields with designed, animated, reusable components.

**Why:** focus landing on a checkbox in a create dialog felt "weird" to the
user, who also called the native browser widgets "ugly".

## AI-filled values are marked and correctable

**SHOULD** · 2026-10 · client dashboard app

Mark AI-filled fields as AI output until a person edits them. Below a
confidence threshold (about 0.8), show a review prompt with the evidence,
the alternative readings, a "looks right" action, and a way to type a
correction ("what if both are wrong?"). Block submit until flagged fields
have been reviewed.

## Accept every common format, then show back one clean one

**SHOULD** · 2026-11 · established UX law

Parse what people type before validating it. Accept spaces, dashes, dots
and brackets in phone, card and IBAN numbers. Trim stray spaces from emails
and pasted values. When the field is left, show the value back in its one
clean format ("+49 30 1234567", "DE89 3704 0044 0532 0130 00"). Then run the
shared strict validators
([formatted fields](#formatted-fields-share-one-strict-validator-set)) on the
parsed value. If parsing really fails, keep what was typed and name the
format that works, with an example. Dates follow
[natural-language dates](#accept-natural-language-for-dates-and-schedules).

**Why:** Postel's law. Rejecting a number because it has spaces moves the
product's work onto the person, and a field that clears what they typed
makes them type it twice.

## Chunk long numbers and format them as people type

**SHOULD** · 2026-11 · established UX law

- **Numbers in groups.** Anything longer than about five characters that
  people read, compare or type is shown in groups: card numbers 4-4-4-4
  (Amex 4-6-5), IBANs in fours, phone numbers in their national format,
  one-time codes as 3 + 3.
- **Format as people type.** Fixed-pattern numbers are grouped while they're
  typed, without moving the caret, and stored without the formatting.
- **Short sections.** Long forms are split into sections of about five
  fields under a heading.
- **Nothing to carry.** Never make people remember a value from one screen
  to enter on the next; show it where it's needed.

**Why:** Miller's law. Working memory holds a handful of items, and a chunk
counts as one, so 16 digits become 4 groups. Typos in grouped numbers are
also easier to spot.

## Don't ask for what you know; default to the free, private choice

**SHOULD** · 2026-11 · established UX law

- **Prefill what the product knows or can infer:** the account's name and
  email, the country from the locale, the city from the postal code
  ([lookups](#lookups-fill-only-empty-fields-and-say-what-they-did)).
- **Default every choice to what most people pick,** and remember last-used
  values (the last project, the last assignee).
- **Help the browser fill the rest:** every field has an `autocomplete`
  attribute.
- **The free, private option is the default.** Never pre-select an option
  that costs money or shares data.
- **Say how long a long task takes,** up front ("about 2 minutes").

**Why:** Tesler's and Parkinson's laws. Complexity the product doesn't take
on, every person pays for every time, and each blank field is an invitation
to stop and think. Pre-selecting what costs or shares is a dark pattern.

## Multi-step forms show where you are and can be resumed

**SHOULD** · 2026-11 · established UX law

- **Where you are.** A form split into steps shows the position and what's
  left ("Step 2 of 4"), with finished steps marked done. A step done before
  the form started (the account exists) counts as done, so progress never
  reads zero after the first action.
- **Resume.** Partial progress is saved, and coming back offers to continue
  where the person stopped.
- **Save in the background.** A step that passes the browser-side check
  saves in the background while the person moves on. A failed save shows a
  toast with Retry and keeps their place. The exception is a step whose saved
  result the next step needs: it waits like a final submit.
- **Motion.** The progress bar grows from its last value and never jumps
  backward ([website-motion P16](../../skills/website/website-motion/patterns.md#p16-progress-in-beats-drawn-checks-arrival-choreography)).

**Why:** the Zeigarnik effect and the goal-gradient effect. Unfinished tasks
stay on people's minds, and people speed up as a goal gets close, so
visible progress pulls them through and a lost draft loses them.

## Show a follow-up field only once it's needed

**SHOULD** · 2026-11 · established UX law

Show the fields most people need. A field that only matters after a certain
answer ("Other…" → a text field, "Invoice to a different address" → the
address) appears once that answer is given, growing in with `Collapse`
([website-motion P2](../../skills/website/website-motion/patterns.md#p2-heightwidth-auto-collapse-animatedimensions-fielderror)).
Rarely used options go behind "More options". Never hide something most
people need.

**Why:** progressive disclosure. Fields shown before they're relevant
are complexity everyone pays for. It pairs with
[requiring only what the step needs](#require-only-what-the-step-needs-mark-required-not-optional).
