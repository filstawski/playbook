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
