---
name: enhance
description: "Installs or updates the ctrl+e prompt enhancer. Pass `fast` or `deep` to switch its mode."
argument-hint: "[fast|deep]"
version: 1.0.0
---

# Enhance

## How the feature works

Pressing `ctrl+e` in the Claude Code chat input triggers the `chat:externalEditor` action. Claude Code reads `$VISUAL` (set via the `env` block in `settings.json`) to find the editor program, writes the current prompt to a temp file, and passes that file path as the first argument.

The script at `scripts/enhance` intercepts that call:

1. If the prompt is empty, opens `$EDITOR` directly for drafting.
2. If the prompt has content, runs the active preset (see Modes) and opens the result in `$EDITOR` for review before submission.
3. On API failure, falls back to opening `$EDITOR` with the original prompt and an error comment.

While the API call is in flight, the terminal shows `[Enhancing prompt... mode: fast]` (or `mode: deep`) so you can see which preset is running.

## Invocation

- `/enhance` (no arg): install or update the feature.
- `/enhance fast`: switch to fast mode.
- `/enhance deep`: switch to deep mode (recommended).

## Modes

The bash script reads `~/.claude/skills/enhance/.mode` on every ctrl+e invocation. It contains a single word that selects the active preset:

- `deep` (fallback if the file is missing, empty, or unrecognized): runs `claude --continue -p ...`. Uses the session model and the full conversation history. Highest quality, slowest on long sessions.
- `fast`: runs `claude --model haiku -p ...`. Uses Haiku 4.5 with no conversation history. Biggest time-to-first-token win on long sessions. Cannot resolve references like "this file" from prior turns, because there is no prior conversation in the call.

### Steps for `/enhance fast` or `/enhance deep`

1. Write the literal word (`fast` or `deep`) to the `.mode` file.
2. Report the new mode back to the user.

## Install / update steps

### Step 1: Verify the script is executable

```bash
ls -la ~/.claude/skills/enhance/scripts/enhance
```

If the executable bit is not set, run:

```bash
chmod +x ~/.claude/skills/enhance/scripts/enhance
```

### Step 2: Verify VISUAL in settings.json

Read `~/.claude/settings.json` and confirm the `env` block contains:

```json
"VISUAL": "~/.claude/skills/enhance/scripts/enhance"
```

If not, update the `VISUAL` value to that path. Report whether the feature was already correctly installed or what was updated.

---

## Script location

`~/.claude/skills/enhance/scripts/enhance` is the single source of truth. There is no copy in `~/.local/bin/`. Edit the script directly; no reinstall is needed after edits, since `VISUAL` points at this path.

## Dependencies

- `claude` CLI (Claude Code, used headlessly via `-p`)
- A terminal editor set in `$EDITOR` (`micro` recommended)

## Evals

A regression suite for `enhance-prompt.txt` lives under `evals/`. Six rule families derived directly from the system prompt (identifier preservation, code-fence preservation, grammar/intent, open-questions surfacing, no-bloat), plus one adversarial fixture for prompt injection.

The primary runner is [promptfoo](https://www.promptfoo.dev). Tests live in `evals/promptfooconfig.yaml`; the shim at `evals/promptfoo-shim` bridges promptfoo's exec contract to `scripts/enhance`'s tmpfile contract. LLM-judge calls go through the local Claude Code OAuth session (no separate API key needed).

The default config covers `fast` mode only. A separate `evals/promptfooconfig.deep.yaml` (with `evals/promptfoo-shim-deep`) covers the `deep` mode `--continue` path: it seeds a conversation, then asserts the enhancer rewrites the prompt instead of continuing the conversation, and that it still resolves references like "that file" from history.

### Usage

```bash
cd ~/.claude/skills/enhance/evals

npm install -g promptfoo            # one-time
promptfoo eval                      # one pass per fixture
promptfoo eval --repeat 3           # variance check
promptfoo view                      # browse results in a web UI
```

Full details in `evals/README.md`.

### Headless flags on `scripts/enhance`

These two env vars are honoured by the script and exist for the eval runners — they are not part of the normal `ctrl+e` flow:

- `ENHANCE_NO_EDITOR=1` — skip the final editor open and exit after the rewrite is written to the temp file.
- `ENHANCE_MODE_OVERRIDE=fast|deep` — take precedence over the `.mode` file for this invocation.
