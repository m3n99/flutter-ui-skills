# flutter-modern-ui — feedback log ({app name})

Keep this file in your project while you work with the skills; add an entry whenever a skill was missing something, contradicted itself, or you had to do something differently. Paths are relative to `plugins/flutter-modern-ui/skills/`.

**Plugin version:** {x.y.z} (commit {sha}) · **Flutter:** {version} · **Platforms:** {…} · **Languages / direction:** {…}

## How to send it upstream

1. Pick the entries with status **open**.
2. Open an issue (or a PR with the fix) on [`m3n99/flutter-ui-skills`](https://github.com/m3n99/flutter-ui-skills), pasting those entries and their summary rows.
3. Mark them **sent → #issue/PR** here. When a release fixes one, mark it **fixed in x.y.z**; the [changelog](../CHANGELOG.md) lists what each release took in.

Start a new log for each plugin version you test (`flutter-modern-ui-feedback-1.1.md`, …) and link the previous one, so it's clear which version every entry was found on.

## Entry format

**N. {Area}** — {confirmed gap / contradiction / new finding} · status: open | sent → #N | fixed in x.y.z

- **What the skill says or lacks:** {quote or describe, with `file:line` or section}
- **What I did instead:** {the concrete solution, values, widget names, and the test or screenshot that shows it}
- **Suggested change:** {one or two sentences: which file, which rule}

## Entries

### Phase {1 — setup, tokens, theme}

1. **{Area}** — {verdict} · status: open
   - **What the skill says or lacks:** …
   - **What I did instead:** …
   - **Suggested change:** …

### Phase {2 — screens}

…

## Summary

| # | Area | Verdict | Status |
|---|---|---|---|
| 1 | {…} | {confirmed gap / contradiction / new finding} | open |

**Highest-value changes, in order:** 1. … 2. … 3. …

## Optional: the design system you ended up with

If your project's DESIGN.md shows a pattern the plugin should ship, attach it (or the relevant section).
