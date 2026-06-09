# gigaideas — filing conventions

This repo is a self-organizing dump of ideas. These conventions are the single
source of truth for how ideas get filed. Both the `/gigadump-idea` and
`/gigadump-organize` commands follow this file.

## What this repo holds

Each idea is one Markdown file. Ideas live in semantically-named category
folders. A root `INDEX.md` is an auto-maintained categorized table of contents.

## Root allowlist (NOT ideas)

Files in the repo root are treated as fresh, unorganized dumps to be filed —
EXCEPT these, which are never moved or treated as ideas:

- `README.md`, `INDEX.md`, `CLAUDE.md`, `LICENSE`, `.gitignore`
- anything under `.github/`, `.claude/`, `docs/`, `templates/`
- any dotfile

## Choosing a category

- Categories are **emergent**: invent folders as themes accumulate; do not force
  a pre-defined taxonomy.
- Prefer an existing folder when an idea clearly fits. Create a new folder only
  when no existing one fits.
- Names are short, lowercase, kebab-case, and meaningful (e.g.
  `developer-tools`, `product-ideas`, `infra`).
- Keep depth sane: at most 3 levels (`category/subcategory/idea.md`). Subdivide
  only when a folder grows past ~8 files.

## Diagrams

- Ideas may include a `## Diagram` section containing a fenced ```mermaid block
  when — and only when — the idea's complexity warrants it (a multi-step flow,
  several interacting components, a state machine, a decision tree, a data model
  with relationships, or a sequence between actors). GitHub renders Mermaid
  inline, so these show up as real diagrams.
- This is added by `/gigadump-idea` at capture time, never forced. Seeds,
  one-liners, and anything a sentence already conveys get no diagram.
  `/gigadump-organize` never adds, edits, or removes diagrams — it only moves
  files and rebuilds `INDEX.md`.

## File naming

- Idea filenames are kebab-case derived from the title, `.md` extension
  (e.g. `auto-organizing-dump.md`). Preserve `.html`/other extensions for raw
  dumps that aren't Markdown.
- On collision, append `-2`, `-3`, …

## INDEX.md format

Regenerate `INDEX.md` after any filing change. It is a **two-part** index: a
compact birds-eye tree for orientation, then a recursive, fully clickable list.
Both reflect the real folder tree at whatever depth it goes.

````
# Index

_Auto-maintained by gigadump. Do not edit by hand._

## At a glance

```
developer-tools/ (4)
├─ cli/ (1)
└─ ide-plugins/ (2)
infra/ (3)
product-ideas/ (5)
└─ marketplaces/ (2)
```

## Full index

### developer-tools — tooling for building software

- **cli/** — command-line tools
  - [CLI scaffolder](developer-tools/cli/cli-scaffolder.md) — generate project boilerplate
- **ide-plugins/** — editor integrations
  - [Auto-organizing dump](developer-tools/ide-plugins/auto-organizing-dump.md) — one-command idea capture
  - [Inline diff lens](developer-tools/ide-plugins/inline-diff-lens.md) — diffs in hover cards
- [Repo-wide TODO scanner](developer-tools/todo-scanner.md) — surface stale TODOs

### infra — deployment & ops notes

- ...
````

### At a glance

- A single fenced code block containing an ASCII tree of **folders only** —
  every category and subcategory, recursively. No leaf idea files here; that is
  what keeps it scannable once the dump is large.
- Annotate each folder with a **recursive idea count** in parentheses: the total
  number of idea files at or below that folder.
- Use `├─`, `└─`, and `│  ` box-drawing connectors for nesting. Top-level
  categories sit flush-left; each level indents under its parent.
- Order every level alphabetically. (Links don't render inside a code block —
  this section is deliberately for orientation, not navigation.)

### Full index

- One `###` heading per top-level category, followed by a recursive bullet list
  of its contents. Continue nesting bullets for any depth of subfolder.
- Each **folder** (category or subcategory) carries a short one-line description
  after an em-dash, **synthesized from the ideas inside it** (regenerated each
  pass — nothing is stored on disk). Top-level categories put it on the `###`
  heading line; subfolders are a **bold `folder/`** bullet with the description.
- Each **idea** is a clickable bullet: `[<Idea title>](relative/path) —
  <one-line summary>`. Derive the summary from the idea's `## The idea` section
  (or the file's first meaningful line for raw dumps).
- Ordering within any folder: **subfolders first (alphabetical), then loose
  ideas (alphabetical)**.

## Hard rules

- NEVER delete idea content. Filing only moves/renames files and edits
  `INDEX.md`.
- NEVER touch the root allowlist or anything under `.github/`, `.claude/`,
  `docs/`, `templates/`.
- Status values for structured ideas: `seed`, `exploring`, `shelved`,
  `promoted`.
