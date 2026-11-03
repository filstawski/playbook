# 13. Working with agents

How agents work with the user: what they may touch, when they ask and when
they act, how they verify and report, and how parallel work is organized.
These are the most repeated rules of all, so every agent should read
[agent-workflow.md](agent-workflow.md) before any task. Added as its own
category on 2026-11-03; before that it was collected under "uncategorized".

| File | Covers |
| --- | --- |
| [agent-workflow.md](agent-workflow.md) | never touch the user's environment, put finished work where they can try it, polish before commits, ask vs act, say what was left out, fix the class of bug, reproduce first, verify yourself, short answers, write corrections down, concept first, rethink legacy, untrusted code, parallel forks, secrets, notifications |

## Know these first

- **Never touch the user's dev database, dev server or uncommitted files.**
  The handover of a finished branch to their checkout is the one wanted
  write.
- **Polish before every "ready to commit", unasked.** Commits still wait
  for an explicit "commit".
- **Plan-only means plan only; "write it down" means document it.**
- **Reproduce before fixing,** and say plainly what wasn't verified.
- **Short answers that lead with the next step.**

Related skills: [code-polish](../../skills/code-polish/SKILL.md),
[git-commit-requires-approval](../../skills/git/git-commit-requires-approval/SKILL.md),
[docs-feature-planning-spec](../../skills/docs/docs-feature-planning-spec/SKILL.md),
[docs-agent-handoff-spec](../../skills/docs/docs-agent-handoff-spec/SKILL.md).
