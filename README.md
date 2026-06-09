# gigadump

A self-organizing idea dump for Claude Code. Capture ideas with one command;
they get filed into a coherent folder tree with an auto-maintained `INDEX.md` —
organized in CI on your **Claude subscription** (OAuth token), with **no
pay-as-you-go API billing**.

## How it works

gigadump is split across **two repos**: the open-source **plugin** (machinery
only, no content) and your **private dump repo** (your ideas plus a copy of the
machinery). You capture locally on your Claude subscription; a GitHub Action
re-organizes in the cloud on the same subscription token.

```mermaid
flowchart LR
    subgraph plugin["📦 gigadump plugin · open source"]
        skill["/gigadump-idea<br/>skill"]
        tmpl["templates/<br/>organize.yml · prompts<br/>taxonomy · idea.md"]
    end

    subgraph local["💻 Your machine · Claude Code"]
        cmd(["/gigadump-idea"])
        cfg["~/.config/gigadump/config.json<br/>dumpRepoPath · defaultStatus"]
    end

    subgraph dump["🗂️ Your dump repo · private"]
        direction TB
        root["root — raw drops<br/>*.md / *.html / *.txt"]
        ideas["category folders<br/>filed idea files"]
        index["INDEX.md — auto TOC"]
        brain["CLAUDE.md — taxonomy 'brain'"]
        wf[".github/workflows/organize.yml"]
    end

    subgraph gh["☁️ GitHub Actions"]
        action["claude-code-action<br/>CLAUDE_CODE_OAUTH_TOKEN<br/>no API billing"]
    end

    skill -. installs .-> cmd
    tmpl == "scaffolds<br/>(first run)" ==> dump
    cmd --> cfg
    cmd -->|"writes + files"| ideas
    cmd -->|updates| index
    brain -. "guides filing" .-> cmd
    brain -. "guides filing" .-> action

    dump ==>|"git push main"| action
    wf -. defines .-> action
    action -->|"files / reorgs + regenerates"| index
    action ==>|"commit [skip organize]"| dump
```

**An idea's lifecycle** — two capture paths, one CI organizer:

```mermaid
flowchart TD
    A([You]) -->|"/gigadump-idea"| B{First run?}
    B -->|yes| BOOT["Bootstrap — scaffold dump repo<br/>from templates + print<br/>one-time GitHub setup checklist"]
    BOOT --> C
    B -->|no| C["Adaptive interview<br/>(more Qs for meatier ideas)"]
    C --> D["Write idea from template ·<br/>file into category folder ·<br/>update INDEX.md"]
    D --> E([commit + push])

    A -. "raw drop (zero ceremony)" .-> R["drop *.md / *.html / *.txt<br/>in repo root"]
    R --> E

    E --> GH{{push to main}}
    GH --> ACT["Action: claude-code-action<br/>authed by OAuth token"]
    ACT --> MODE{trigger?}
    MODE -->|default push| N["file only new<br/>root dumps"]
    MODE -->|"[reorg-all] / manual button"| F["restructure<br/>whole tree"]
    N --> IDX["regenerate INDEX.md ·<br/>commit [skip organize] · push"]
    F --> IDX
    IDX -. "if: guard skips<br/>organizer's own commits" .-> GH
```

## Install

```
/plugin marketplace add GigaFlow-AI-Incorporated/gigadump
/plugin install gigadump
```

## Use

Run `/gigadump-idea`. On first run it bootstraps your dump repo (asks where it
should live, scaffolds the workflow + conventions + templates, and prints a
one-time GitHub setup checklist). After that, every run:

1. Runs a short, adaptive interview (more questions for meatier ideas, fewer for
   quick seeds).
2. Writes a structured idea file and files it into the right category folder.
3. Updates `INDEX.md`.

Then you `commit` + `push`. You can also just drop a raw `.md`/`.html`/`.txt`
file in your dump repo's root and push — a GitHub Action files it for you.

## How organizing works

The bootstrap installs a GitHub Action in your dump repo. On push to `main` it
organizes new root files; with `[reorg-all]` in the commit message (or the
manual **Run workflow** button) it restructures the whole tree. It authenticates
with a `CLAUDE_CODE_OAUTH_TOKEN` secret you generate via `claude setup-token`.

## Config

Per-user state lives in `~/.config/gigadump/config.json`
(`{ "dumpRepoPath": "...", "defaultStatus": "seed" }`).

## License

MIT
