# Navigation and structure

How areas, pages and breadcrumbs are organized, in apps and on sites.

## Breadcrumbs start with a section, never with a record's name

**MUST** · 2026-10 · dashboard apps (2 sources)

Every breadcrumb trail starts with its list page, or with what the record
is ("Projects › Website relaunch › Tasks"). If no list page exists, the
prefix is a plain label (no hover, no pointer). On phones, keep the trail to
two crumbs rather than truncating all of them. A correction on one page
applies to every page of that kind ("I told you multiple times … fix all
pages").

## One nav entry and URL root per area

**SHOULD** · 2026-10 · dashboard app

When an area grows several pages, give it one sidebar entry and one URL
root, with route tabs:

- Show each tab only to users who may use it; others land on their first
  allowed tab.
- Detail pages stand alone, without tabs, and get breadcrumbs.
- When URLs move, add permanent redirects. Links in sent emails and stored
  notifications still point at the old ones.

**Why:** the user found the sidebar entries and URL routing "a bit off" and
asked for them to be organized better.

## Every new page needs a visible entry point

**SHOULD** · 2026-08 · dashboard app

When adding a page, also add the link or button that reaches it (a nav item,
or a header button next to the related action), gated by the same permission
as the page ("where is the button to get to the invite page?").

## Overview pages show problems first

**SHOULD** · 2026-10 · dashboard app

Don't squeeze status, catalogue and log onto one page:

- The overview holds what to act on first (failures, waiting items).
- Then a few numbers, each linking to the filtered list. A failure count
  turns red above zero.
- Large collections become route tabs with their own URLs, pagination and
  filters, so a thousand entries don't bloat the page.

## Quiet records

**SHOULD** · 2026-10 · dashboard apps

A record page shows one primary action. Secondary actions sit in a ⋯ menu
next to the title, and empty sections aren't rendered. On phones,
page-header actions sit beside the title as icon buttons, the same on every
page.

**Why:** the user disliked "a lot of buttons next to each other" on a record
page. On phones, some header actions sat beside the title and others on the
next line, which the user wanted made consistent on every page.

## On a marketing site, each page has one job

**SHOULD** · 2026-10 · company website

Content held in full on one page is only linked from the others. Don't
repeat scope lists on the home and services pages, or duplicate a "how we
work" section on every service page. A home page order that worked: offer →
the visitor's situation → process → terms → who you are → contact.

## Settings as a hub of areas

**CONSIDER** · 2026-10 · client dashboard app

Admin settings are a hub page of large cards (a description and a live
count each, shown only to roles that may open them; planned areas greyed),
with each area on its own page, not a tab (its anatomy is in
[layout-and-typography.md](../design-guidelines/layout-and-typography.md#settings-pages-reuse-the-record-pages-anatomy)).
Toggle changes collect in a save bar that says what changes and for whom.

**Why:** the user asked for the system settings to stop being tabs: "like
in big cards with descriptions".
