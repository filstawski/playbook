# Open questions

These came up while consolidating Aug–Nov 2026, either as genuine conflicts
between sources or as choices that might have been one-offs rather than
rules. Each item lists the evidence and a leaning. Nothing here is treated
as a rule until it is decided; where the playbook had to say something, it
says the leaning and links here.

## Workflow and git

1. **Rebasing open PR branches.** The stated rule (Oct 26 – Nov 1) was:
   never force-push; merge main into the branch. On Nov 2, during a large
   parallel batch, open PRs were rebased onto main instead, and you didn't
   object ("fix merge conflicts", "looks good, merged").
   *Leaning:* keep "merge main in" for branches with an open PR, and allow
   rebasing only branches nobody has seen.
   → [branches-and-history.md](guidelines/version-control/branches-and-history.md)
2. **Committing a deploy-blocking fix unasked.** Once, a lockfile-only fix
   was committed and pushed without asking, because the preview server
   builds only pushed code. It was disclosed afterwards and you didn't
   object. Is that an accepted exception?
   *Leaning:* no, still ask, but say why it blocks.
3. **Delegated release paths.** In the Deployer repo you said "feel free to
   commit and force push and do the tag stuff". Does such a delegation
   cover the whole session for that repo, or only that release?
   *Leaning:* the session, in repos where you said you won't review the
   code.
4. **Straight to main on solo repos.** One prototype's history goes straight
   to main. Is that fine for solo prototypes in general, or should
   everything go through PRs?
   *Leaning:* follow each repo's established flow (current guideline).
5. **Backups of rejected work.** "Back up before a risky refactor" (tags,
   snapshot refs) sits next to "a discard means gone; no hidden backups of
   rejected work". Is a backup ref for something you rejected wanted?
   *Leaning:* back up before risky changes; delete backups of work you
   explicitly rejected.
6. **Auto-backing up design variants to branches.** An early request was to
   back up design variants to branches automatically, which conflicts with
   commit-only-when-asked.
   *Leaning:* local snapshot refs, not commits.

## Design and motion

7. **Motion (JS) vs CSS.** In September you insisted on the `motion` library
   over CSS ("the motion animations were much cleaner than the CSS ones").
   Since October, swaps, overlays and hovers run as CSS transitions that
   use the same springs (generated `linear()` curves), and you approved
   the results. The skill now says: CSS with the shared spring curves for
   compositor-friendly swaps, `motion` for layout, presence and physics.
   That is an inference; please confirm.
   → [website-motion](skills/website/website-motion/SKILL.md)
8. **Bounce on client sites.** The client-site template ships no-bounce
   tweens (`bounce: 0`), chosen by an agent and never explicitly approved,
   while your own sites repeatedly asked for more bounce. Should client
   sites use the site profile's springs?
   *Leaning:* yes, the site profile, tuned per business.
9. **Scroll reveals and parallax.** An earlier company-site concept banned
   parallax layers, magnetic buttons, count-up numbers and "every section
   fading in on scroll". Later sites use scroll reveals and a parallax
   primitive, and you asked for "scroll effects" on client sites. Which
   bans still stand?
   *Leaning:* allow reveals and light parallax under the motion rules; keep
   the bans on magnetic buttons, count-ups and scroll-jacking.
10. **Loops.** The codified rule is "continuous motion only where asked, and
    only on chrome and AI surfaces, never on content objects". Confirm.
    *Leaning:* yes.
11. **Ambient effects: "default to less" vs "too faint".** Interactive
    feedback starts subtle, but an ambient effect built so faint you missed
    it was "too faint".
    *Leaning:* ambient effects clearly visible but few.
12. **Sound effects in apps.** A sound concept was written down (few,
    meaningful, quiet, generated with the Web Audio API) but not approved.
    Build it, or drop it?
    *Leaning:* leave it written down and unbuilt until you ask.
13. **Selection mark.** The newest app replaced the `layoutId` indicator with
    a hand-stepped liquid "bead". The skill ships `layoutId` as the default
    and the bead as an option. Correct?
    *Leaning:* yes.

## Websites, SEO and copy

14. **Analytics on public sites.** You asked for Google Analytics at a
    launch, the agent advised against it (consent banner, contradicts the
    "no cookies" claim), and nothing was added; your answer isn't recorded.
    Is "no analytics, Search Console only" the standing rule?
    → [monitoring-and-analytics.md](guidelines/external-services/monitoring-and-analytics.md)
15. **Title order.** The template's home title is brand-first
    (`Name – Trade in City`); the SEO audit rule on the company site is
    query-first, brand last. Which should client sites use?
    *Leaning:* query-first on service pages; the brand-first home title is
    fine for a business that is searched by name.
16. **Service URL shape.** `/leistungen/<service>` (older site) or top-level
    `/<service>` (newest site)?
    *Leaning:* top-level `/<service>`, the newest choice.
17. **Back-port to the template.** The newest client site added things the
    template lacks: legal-page descriptions, the consumer-dispute statement,
    a professional-rules link in the legal notice. Back-port them?
    *Leaning:* yes.
18. **Small SEO details for the template:**
    - typed JSON-LD with `BreadcrumbList` and `Service` on service pages;
    - sitemap `lastModified` taken from content;
    - one share image per page instead of one per site;
    - `llms.txt` and `security.txt` on client sites.

    *Leaning:* typed JSON-LD and content-based `lastModified` yes; one share
    image per site until a page needs its own; skip `llms.txt` for small
    client sites.
19. **Production hosting for client sites.** Previews are Deployer, but
    where client sites run in production is undecided (one older site runs
    on GitHub Pages).
    *Leaning:* the production pattern in `deploy-docker-compose-vps`,
    simplified for a static site, or a static host the client already has.
20. **When a client site gets a server-side form.** Today it's "a decision in
    the concept", with photo uploads as the likely trigger. Fix a rule?
    *Leaning:* keep "a decision in the concept"; attachments are the usual
    trigger.
21. **Showcasing internal side projects** on the company site before there
    are client references: wanted or not?
    *Leaning:* not before there are real client references.

## Stack and dependencies

22. **The two-week rule for security updates.** One session applied "the
    newest patched release that has been out ≥ 2 weeks" as a standing
    constraint, but where it came from isn't visible (maybe a global
    setting). Confirm it as a rule.
23. **Updating the existing dashboard skills.** `website-nextjs-dashboard-stack`
    describes Radix-based shadcn and TanStack Query (the thin-client
    dashboard). Newer apps use Base UI-based shadcn and own their backend,
    and the newer `components/ui` placement rule overrides the
    project-structure skill's wording. This consolidation only added notes.
    Should those skills be revised in place?
    *Leaning:* revise `project-structure` for the placement rule, and keep
    `dashboard-stack` as the thin-client variant with a newer sibling.

## Structure of the playbook

24. **New categories.** "Working with agents" (`guidelines/uncategorized/agent-workflow.md`)
    holds the most repeated rules of all, and "Client work" is a coherent
    set too. Promote them to categories 13 and 14?
    *Leaning:* yes for "Working with agents"; "Client work" can stay
    uncategorized until it grows.
25. **Root README install instructions.** They now describe the `skills`
    CLI as the primary way (what every project uses) and keep symlinking as
    an alternative. Fine?
    *Leaning:* yes.
26. **A project name in the existing SDK skills.** The pre-existing
    `skills/sdk/*` code examples (5 files) name the API client after the
    project they came from (`this.hematite`). This pass left existing skills'
    content alone. Rename it to a generic `this.client`?
    *Leaning:* yes, in a separate small PR.

## Already resolved (newest source wins, no decision needed)

- **UI text:** label modules, not inline (newest projects enforce it).
- **Placeholders:** a bare example, no "e.g." prefix.
- **Input focus:** brand accent, unless the brand is red (then neutral).
- **Visual verification:** agents verify before reporting (since October),
  never on your dev server; replaces August's "I'll verify myself".
- **Answer length:** short, plain, next step first (Oct 30), replacing
  "explain more" (Oct 6).
- **Stacked PRs:** serial by default, all at once against main when you
  ask.
- **Previews:** Deployer replaced the GitHub-Pages-based tool on
  2026-10-12.
- **The liquid-glass design language** is outdated and not used (your
  instruction, 2026-11-02).
- **Scope selectors vs permission pages:** within-page scope selectors
  fall back to "mine"; pages the viewer can't open show an explicit
  "no permission" page.
