# <Topic>

<!--
A guideline file holds the rules for one topic inside one category of
guidelines/ (e.g. guidelines/frontend/forms.md). Copy this file to start a
new topic. Keep entries short: a rule an agent can follow without reading
the rest of the file. Anything that needs pages of code belongs in a skill
under skills/, and the entry here links to it.
-->

One or two sentences on what this topic covers and when an agent should
read it.

## <Short imperative title: "Use X for Y">

**MUST** · 2026-10 · <generic project type, e.g. "dashboard app", "marketing site">

The rule, stated as an instruction: use X for Y because Z. One to three
sentences, specific enough to act on.

**Why:** the reasoning, or the incident that produced the rule.

```tsx
// do
<Example />

// don't
<CounterExample />
```

**Changed:** (only if the preference changed) what it used to be, when it
changed, and why.

**See also:** [related-skill](../../skills/<domain>/<related-skill>/SKILL.md)

<!--
Strength:
  MUST     hard rule: stated as always/never, a firm correction, or repeated
  SHOULD   the default; deviate only with a reason
  CONSIDER situational; worked well where it was used

Source line: approximate date (month is enough) and a generic project
type. Never a project, client, or company name, a domain, or a URL — this
repository is public.

A rule taken from published UX research rather than from the user's
projects says "established UX law" instead of a project type, names the law
in **Why:**, and is never stronger than SHOULD. Where it disagrees with a
rule from the user's projects, the user's rule wins; say so in the entry.
A user decision that hasn't come up in a project yet adds
"(decided YYYY-MM-DD)" after the project type.
-->
