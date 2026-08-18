# dotclaude

A personal [homeshick](https://github.com/andsens/homeshick) castle for
[Claude Code](https://code.claude.com) configuration. The repository's
`home/.claude/` directory is linked to `~/.claude/` when the castle is
symlinked.

This castle is intentionally personal rather than a portable default
configuration. Some settings refer to local macOS, Homebrew, iTerm2, and
absolute `/Users/ira/...` paths; review `home/.claude/settings.json` before
installing it on another machine.

## Companion repositories

- [My dotfiles](https://github.com/seefood/dotfiles)
  is the broader homeshick castle for shell, editor, and general home-directory
  configuration. Claude Code configuration was moved out of that castle into
  this repository in July 2026.
- The skills companion is [My claude plugins](https://github.com/seefood/ira-claude-plugins).
  It publishes self-authored Claude Code skills as an installable plugin
  marketplace. It is separate from the locked skill snapshots stored here.

## Installation

Install homeshick, if necessary:

```bash
git clone https://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
```

Then clone and symlink this castle:

```bash
homeshick clone seefood/dotclaude
homeshick link dotclaude
```

The symlink maps files under `home/.claude/` to your  `~/.claude/`


To remove the symlinks without deleting the castle checkout:

```bash
homeshick unlink dotclaude
```

## Contents

```text
home/.claude/
├── CLAUDE.md                         Global Claude Code instructions
├── settings.json                     Settings, hooks, permissions, and plugins
├── commands/rate-me.md               Custom /rate-me command
├── hooks/                            Notification and post-tool hooks
├── scripts/validate-bash.sh          PreToolUse command validation
├── statusline*.sh                    Alternate status-line scripts
├── super-status/                     Active status line and diagnostics
├── claude-*.json                     Powerline/status-line configuration
└── skills/
    ├── enhance/                      Locked third-party snapshot
    ├── nfr-analyst/                  Locked third-party snapshot
    └── challenger/                   Locked third-party snapshot
```

`.homesick_subdir` lists the Claude subdirectories that homeshick must create
before linking the castle.

## Locked skill snapshots

The following directories are copied from vetted upstream commits and are
kept byte-identical to those reviewed versions. They are not live submodules
or subtrees, so upstream changes cannot silently change the installed content:

| Local skill | Upstream | Pinned commit |
| --- | --- | --- |
| `enhance` | [dannycohen/enhance](https://github.com/dannycohen/enhance) | [`cf56566`](https://github.com/dannycohen/enhance/commit/cf56566) |
| `nfr-analyst` | [dannycohen/nfr-analyst](https://github.com/dannycohen/nfr-analyst) | [`95db727`](https://github.com/dannycohen/nfr-analyst/commit/95db727) |
| `challenger` | [eranshir/challenger](https://github.com/eranshir/challenger) | [`3a4c41c`](https://github.com/eranshir/challenger/commit/3a4c41c) |

Do not edit these snapshots or run formatting/autofix hooks over them. Their
exclusions are maintained in [`.pre-commit-config.yaml`](.pre-commit-config.yaml)
and [`.gitattributes`](.gitattributes). Re-vetting an upstream update is an
explicit, manual operation.

The self-authored skills published by `ira-claude-plugins` are installed and
updated through the Claude Code plugin marketplace rather than by modifying
these snapshot directories.

## Development and validation

Run the repository-wide checks with:

```bash
prek run --all-files
```

Install the repository's pre-commit hooks with:

```bash
prek install
```

To check one shell script directly:

```bash
shellcheck path/to/script.sh
```

## License

See [LICENSE](LICENSE).
