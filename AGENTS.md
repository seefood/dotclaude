# Agent Instructions for dotclaude

A homeshick castle holding personal Claude Code configuration
(`home/.claude/`): settings, hooks, scripts, statusline/powerline configs,
and skills — both self-authored and locked third-party snapshots.

## Build/Lint/Test Commands

- **Lint**: `prek run --all-files` (trailing whitespace, shellcheck, shfmt, json-sort, git-check)
- **Install hooks**: `prek install`
- **Test a single shell script**: `shellcheck path/to/script.sh`

## Repository Structure

- `home/.claude/` — symlinked into `~/.claude` via `homeshick symlink dotclaude`;
  see `.homesick_subdir` for which subdirectories must be pre-created first
- `home/.claude/skills/{enhance,nfr-analyst,challenger}/` — **locked third-party
  snapshots**, pinned at a specific vetted commit (see README.md for the exact
  refs and upstream repos). Never edit their contents, and never let a
  formatting hook rewrite them — that breaks byte-identity with what was
  reviewed. Their exclusions live in `.pre-commit-config.yaml` and
  `.gitattributes`.
- `home/.claude/skills/debugging-with-the-scientific-method/` — self-authored,
  no such restriction; edit freely.
- Everything else under `home/.claude/` (settings.json, hooks/, scripts/,
  commands/, statusline*/powerline configs) — self-authored, edit freely.

## Code Style Guidelines

### Shell scripts (hooks/, scripts/, statusline*.sh)

- `#!/bin/bash` shebang, executable bit set
- shellcheck/shfmt clean (enforced by prek)

### JSON (settings.json, powerline configs)

- 2-space indentation, keys sorted (enforced by `json-sort` in prek)

### Adding a new locked third-party skill

1. Vet it first (see the `test-before-install` plugin in the sister repo
   `ira-claude-plugins`).
2. Copy the exact vetted commit's files verbatim — no reformatting.
3. Add its path to the exclude regex in `.pre-commit-config.yaml`
   (trailing-whitespace, end-of-file-fixer, mixed-line-ending, shfmt,
   json-sort) and to `.gitattributes` (`-whitespace`).
4. Credit the author and link the source repo + pinned commit in README.md.
