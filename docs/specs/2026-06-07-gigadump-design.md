# gigadump — design (v2: open-source tool + content split)

**Date:** 2026-06-07
**Status:** Approved, pre-implementation

## Concept

`gigadump` is an **open-source Claude Code plugin** that gives you a
self-organizing idea-dump repository. You capture ideas two ways; Claude
(authenticated via your Claude subscription, **no API billing**) files them into
a coherent folder tree and maintains an index.

The tool ships no ideas of its own. Your ideas live in a **separate, private
content repo** that the tool scaffolds and writes into.

## Two repositories

### 1. `gigadump` — the tool (this repo, open source)

A Claude Code plugin distributed via a marketplace (same mechanism as `cns` /
`superpowers`). Users install with:

```
/plugin marketplace add <owner>/gigadump
```

Contains only machinery — no personal content:

```
gigadump/
├─ .claude-plugin/marketplace.json   # marketplace manifest
├─ plugin.json                        # plugin manifest (name, version, skills)
├─ skills/idea/SKILL.md               # the single /gigadump-idea command
├─ templates/
│  ├─ organize.yml                    # GitHub Action (copied into content repo)
│  ├─ organize-prompt.md              # organizer instructions
│  ├─ taxonomy-CLAUDE.md              # filing conventions (copied into content repo)
│  ├─ idea.md                         # idea front-matter + section template
│  └─ README.md                       # README seeded into a new content repo
├─ docs/specs/                        # design docs
└─ README.md                          # install + usage
```

### 2. The content repo (private, per-user)

Created/scaffolded by the tool on first run. Holds the actual ideas plus the
copied-in machinery. The GitHub Action runs **here**.

```
<your-dump>/                          # e.g. ~/Projects/idea-dump
├─ .github/workflows/organize.yml
├─ .github/organize-prompt.md
├─ CLAUDE.md                          # taxonomy conventions (from template, then yours)
├─ templates/idea.md
├─ INDEX.md                           # auto-maintained categorized TOC
├─ README.md
└─ <emergent category folders…>
```

## Single smart command: `/gigadump-idea`

One user-facing command. It self-bootstraps:

1. **Read config** at `~/.config/gigadump/config.json`.
2. **If no dump repo is configured** → run inline setup:
   - Ask the user to create a new dump repo or point at an existing one.
   - Scaffold it from `templates/` (workflow, `organize-prompt.md`, taxonomy
     `CLAUDE.md`, `templates/idea.md`, `INDEX.md`, `README.md`).
   - Print the one-time GitHub setup checklist (see below).
   - Save the repo path to `~/.config/gigadump/config.json`.
3. **Capture the idea** — adaptive interview:
   - Seed/throwaway thought → 0–1 questions, file fast.
   - Meatier idea → a few sharpening questions; never forces structure on a
     seed.
4. **Write + file** the structured doc from `templates/idea.md` into the right
   folder per the content repo's `CLAUDE.md`, and update `INDEX.md`.
5. Leave the working tree ready to commit + push.

### Config file (`~/.config/gigadump/config.json`)

```json
{
  "dumpRepoPath": "/Users/<you>/Projects/idea-dump",
  "defaultStatus": "seed"
}
```

`/gigadump-idea` reads `dumpRepoPath`; if missing/invalid, it re-runs setup.
This decouples the read-only shared plugin from per-user state.

## Capture paths (content repo behavior)

- **`/gigadump-idea`** (polished): structured, already-filed, index updated
  locally on your subscription. Just commit + push afterward.
- **Raw dump** (zero-ceremony): drop any file (`.md`/`.html`/`.txt`/…) in the
  content repo **root**, commit, push to `main`. The Action files it.

## The organizer Action (in the content repo)

Identical behavior to v1, now sourced from `templates/organize.yml`:

- **Triggers:** `push` to `main` + `workflow_dispatch`.
- **Loop guard:** organizer commits carry `[skip organize]`; workflow `if:`
  skips those; `concurrency:` prevents overlap.
- **Engine/auth:** `anthropics/claude-code-action` authed by a
  `CLAUDE_CODE_OAUTH_TOKEN` repo secret (`claude setup-token`) → no API billing;
  `contents: write` to push back.
- **Default mode:** file only new root dumps; never move filed ideas.
- **Full reorg:** commit msg contains `[reorg-all]` OR manual button → may
  restructure the whole tree.
- Both modes regenerate `INDEX.md`, commit with `[skip organize]`, push.
- **Failure = no-op:** dump stays in root, retried next push.

## Shared taxonomy ("the brain")

`templates/taxonomy-CLAUDE.md` (becomes the content repo's `CLAUDE.md`) is the
single source of filing truth — how to choose/name folders (emergent, sane
depth), the root allowlist, the `INDEX.md` format. Both `/gigadump-idea` and the
Action's `organize-prompt.md` reference it so local and cloud filings agree.

## What counts as "unorganized" (content repo root)

Any root file EXCEPT the allowlist: `README.md`, `INDEX.md`, `CLAUDE.md`,
`LICENSE`, `.gitignore`; anything under `.github/`, `.claude/`, `docs/`,
`templates/`; and dotfiles.

## `templates/idea.md`

```
---
title:
created:
status: seed        # seed / exploring / shelved / promoted
tags: []
category:
---
## The idea
## Why it's interesting / problem it solves
## How it might work (rough)
## Open questions
## Related   ([[links]] to sibling ideas)
```

## One-time GitHub setup (printed by setup; documented in tool README)

1. Create the GitHub repo for your dump and push.
2. Run `claude setup-token` → generates an OAuth token.
3. Add it as the `CLAUDE_CODE_OAUTH_TOKEN` repository secret.
4. Ensure Actions have write permission (workflow declares `contents: write`;
   confirm repo Actions settings allow it).

## Open-source housekeeping (tool repo)

- `LICENSE` (MIT suggested), `README.md` with install + quickstart, a short
  `CONTRIBUTING.md`.
- The plugin ships only generic templates; no personal data.

## Decisions locked

- Distribution → Claude Code plugin/marketplace.
- Naming → tool repo = `gigadump`; personal content repo renamed (currently
  `~/Projects/idea-dump`).
- Command surface → single smart `/gigadump-idea` that self-bootstraps setup.
- Per-user state → `~/.config/gigadump/config.json`.
- Reorg scope → new files by default; full reorg on demand.
- Engine → `claude-code-action` + subscription OAuth token (no API billing).
- Index → auto-maintained root `INDEX.md`. `/idea` depth → adaptive. Categories
  → emergent.
