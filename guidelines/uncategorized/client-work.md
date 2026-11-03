# Client work

> **Flagged as uncategorized.** Rules for delivering work to small-business
> clients: messages, change requests, handover, legal pages. They don't fit
> the categories, and stay here until the set grows (decided 2026-11-03).

## Confirm understanding of a change request before editing

**MUST** · 2026-10 · client site

Read every document the customer sent and the current site, then restate
the change list page by page, and stop. Cross-check problems you found
against the change document, so you don't raise what it already changes.
Give exact locations (file and line, PDF page) so the user can verify, and
apply changes only after their answer.

## Customer messages: short, ready to paste, in their language

**SHOULD** · 2026-10 → 2026-11 · client sites

When asked for a reply to a customer, write it ready to copy in the
customer's language (German with the formal *Sie* unless told otherwise),
plain and short, as numbered questions or a few bullets, with no internal
jargon. Default to shorter; the user trims further if needed. Meeting and
client-facing material is short and sized to the meeting.

**Why:** the user asked for shorter drafts ("Keep it simple", "Shorter
reply"). A first meeting pack ran to about 1,100 lines, which the user said
would take six hours to present; about 120 lines fit a 45-minute meeting.

## Speculative previews for prospects are rough drafts

**SHOULD** · 2026-11 · client sites

When sending a prospect an unsolicited preview site, say it is a first rough
draft, made from their old site without their input, and not a finished
product:

- texts, colours and images aren't agreed;
- it is non-binding;
- nothing on it was invented;
- it isn't on Google;
- when the preview expires.

Add a short highlight list and ask for brief feedback.

## Legal pages are generated from the site's facts

**MUST** · 2026-11 · client sites (German)

The legal notice (Impressum, "Angaben gemäß § 5 DDG", no longer TMG) and the
privacy policy are generated from the single `SITE` facts object. They
describe what the site actually does: no cookies, no tracking, self-hosted
fonts, a `mailto:` form. Optional blocks (register entry, VAT ID,
professional chamber, liability insurance) appear only when the facts exist.
Ask the owner for missing legal facts instead of guessing. A sole owner's
private address appears only where the law requires it.

**Why:** facts repeated by hand across a site's pages turned each customer
change into multi-file edits and left contradictions behind. The user also
didn't want their home address on the main page.

## Hand over with a client README and a launch checklist

**SHOULD** · 2026-11 · client sites

Before handover, rewrite `README.md` for the client (what the site is, how
to develop it, where things live, how it deploys), and delete the build
prompt. Going live follows a checklist:

- [ ] The owner has reviewed the copy, the legal facts and any redrawn logo.
- [ ] Open questions are closed and no TODO is left.
- [ ] A production host is chosen, without the preview environment variable.
- [ ] There is one canonical origin, and old addresses redirect (checked with `curl -I`).
- [ ] DNS and TLS work on the bare domain and on `www`.
- [ ] Search Console is set up with the sitemap.
- [ ] The Business Profile and directory listings match the legal notice.

## Sales-demo prototypes tell a story with honest data

**SHOULD** · 2026-10 · prototypes

A prototype for a prospect optimizes for what can be shown at the next
meeting: reuse standard tables and boards, spend the effort on the novel
part, and write a scripted demo flow. It runs fully offline on the
presenting laptop. All data is fictional and labelled as a simulation; it
never implies knowledge of the client's internals, never puts real people's
names on invented records, and never uses their logo.

**Why:** "the prototype shouldn't focus on code, but on the fact that we can
show them something next meeting."

## Reports are reusable tools

**SHOULD** · 2026-10 · prototype

When asked for a script that produces a report, ship a re-runnable tool: an
installable command, a fixed output folder, history with "changes since last
run", filters, exit codes for alerting, and a README with scheduling
examples. ("I expected something more reusable, like a script I can use in
future, and not a one-time record only.")

## Don't reuse a component licensed for one project

**SHOULD** · 2026-10 · brand assets

A third-party component or asset licensed for one project isn't copied
into other deliverables. Check the licence before reuse.

## Don't showcase internal projects before there are client references

**SHOULD** · 2026-11 · company website

The company's own site shows client work once there are real, approved
references. Internal side projects don't fill that space in the meantime.

**Why:** decided 2026-11-03, after the question came up while planning a
references section.
