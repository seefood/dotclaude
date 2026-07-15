# Enhance evals

Regression suite for the `enhance` skill's system prompt (`scripts/enhance-prompt.txt`), driven by [promptfoo](https://www.promptfoo.dev).

## Why

Every change to the system prompt is otherwise a vibes-based decision. This harness turns it into a maintained artifact: each rule in the prompt is anchored to one or more fixtures, so deltas are visible.

## What it checks

Six rule families derived from `scripts/enhance-prompt.txt`:

1. **Identifier preservation** — function names, paths, URLs, flag names appear in output exactly as in input.
2. **Quoted-text and code-fence preservation** — anything inside `"..."`, backticks, or fences is byte-identical.
3. **Grammar / clarity improvement** — output is at least as readable (LLM-judged).
4. **Intent preservation** — meaning doesn't drift (LLM-judged).
5. **Open-questions surfacing** — ambiguous inputs produce an `**Open questions**` section.
6. **No bloat** — output token count is bounded by ratio for `tighten` / `expand` fixtures.

Plus one **adversarial** fixture that verifies a prompt-injection attempt doesn't redirect the rewriter.

## Install

```bash
# One-time:
npm install -g promptfoo
# or use without installing:
npx promptfoo@latest --help
```

No Anthropic API key is required — `promptfooconfig.yaml` uses `apiKeyRequired: false` to authenticate LLM-judge calls via your local Claude Code OAuth session.

## Run

```bash
cd ~/.claude/skills/enhance/evals

# Single pass through every test
promptfoo eval

# Variance check (run each test 3 times)
promptfoo eval --repeat 3

# Browse results in the web UI
promptfoo view
```

`promptfoo eval` writes to `~/.promptfoo/output/` by default. Pass `--output results.json` for a local file.

### Deep-mode suite

The default config only exercises `fast` mode (a clean session, no `--continue`). The `deep` path — where `--continue` replays the live conversation — has its own config, because that path once continued the conversation instead of rewriting:

```bash
promptfoo eval -c promptfooconfig.deep.yaml
promptfoo eval -c promptfooconfig.deep.yaml --repeat 3   # variance check
```

It is slower and pricier than the fast suite: each test seeds a real session with the default model before running the deep enhancer call.

## How it talks to `scripts/enhance`

`promptfoo-shim` is the bridge. Promptfoo's `exec` provider passes the rendered prompt as `argv[1]`; our `scripts/enhance` takes a tmpfile path. The shim:

1. Writes the prompt to a tmpfile.
2. Sets `ENHANCE_NO_EDITOR=1` and runs `scripts/enhance <tmpfile>`.
3. Prints the rewritten tmpfile contents to stdout (what promptfoo captures as the "model output").

`ENHANCE_MODE_OVERRIDE=fast` is set in the provider config in `promptfooconfig.yaml`. The on-disk `.mode` file is not touched.

`promptfoo-shim-deep` is the deep-mode counterpart used by `promptfooconfig.deep.yaml`. It first seeds a topically-rich conversation in a throwaway cwd (so `--continue` has history to resume), then runs `scripts/enhance` there with `ENHANCE_MODE_OVERRIDE=deep`.

## Adding a test

Edit `promptfooconfig.yaml`. Each test is a `description` + `vars.prompt` + `assert[]`. Assertion types we use:

| Type | What it does |
|---|---|
| `contains` / `not-contains` | substring present / absent (byte-exact) |
| `llm-rubric` | LLM-as-judge with a rubric; `threshold: 0.8` ≈ score 4/5 |
| `javascript` | custom check; we use it for markdown-section presence and word-ratio bounds |

Full reference: [promptfoo assertion types](https://www.promptfoo.dev/docs/configuration/expected-outputs/).

## Cost

Default config: 15 tests × (1 SUT call + ~1 judge call where applicable) ≈ 25 Haiku calls per `promptfoo eval`. Under $0.02. With `--repeat 3`, triple that. The Claude Code OAuth path uses your existing subscription, not metered API tokens.

## Acceptance criterion for the harness itself

A test change that intentionally weakens `enhance-prompt.txt` (e.g. delete the "Do not paraphrase technical terms" line) must produce ≥3 failing tests. If it doesn't, the fixture set has gaps.
