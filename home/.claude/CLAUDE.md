# CRITICAL RULES - PRIORITY 1

## Verification

- Before suggesting commands/configs/implementations: State "Let me verify this approach in official documentation"
- If cannot verify: State "I cannot verify this approach exists/works"
- If uncertain: State "This is unverified/my guess", It is better to say "I don't know" than to state a guess as a fact.
- Never suggest unverified: install commands, config syntax, API usage, CLI flags, file paths, deployment steps

## Git Operations

- Commit after every completed task
- Git commit successful only if exit code = 0
- NEVER use `commit --no-verify` without explicit user permission
- If pre-commit hooks fail: STOP, ask user how to proceed
- Task is NOT complete until commit passes hooks cleanly

## Environment Management

- Python: ALWAYS `uv sync --frozen`, NEVER `uv venv + uv pip install`. same for pixi, npm, etc.
- After pyproject.toml / pixi.toml changes: `uv lock` then commit lock file
- All package managers: ONLY use locked/frozen modes at build time / CI
- Always mark lock files as binary in .gitattributes

## Code Quality

- Before task completion: Run `mcp__ide__getDiagnostics`
- Fix all linting/type errors before considering task complete
- Apply to any file created/modified

## Communication

- Show expanded todo list by default
- Avoid pleasantries ("excellent question", etc.)
- Assume talking to senior engineer

# STANDARD RULES - PRIORITY 2

## Git Workflow

- Small commits better than large
- Descriptive commit messages
- Update documentation when relevant
- Feature branch naming: `feature-name/###-phase-name` (e.g., `queue-ui/001-specification`, `multiqueue/003-phase-2`)
  - Format: lowercase-with-hyphens / three-digit-number - lowercase-with-hyphens
  - Never merge to default branch without explicit user request
  - Each feature typically has multiple phases with sequential numbering

## Package Management

- Prefer isolation over system-wide: `uv tool install` > `pip install --user`
- Node: `npx` > local installs > global

## CLAUDE.md Management

- Commit changes to dotfiles repo after modifications
- Pull remote updates daily: `cd ~/.homesick/repos/dotfiles && git pull`
- Sync command: `cd ~/.homesick/repos/dotfiles && git add home/.claude/ && git commit -m "Update Claude Code global settings" && git push`

# SELF-IMPROVEMENT

## Rule Updates

- New tech/pattern used in 3+ files → add rule
- Common bugs preventable → add rule
- Code review feedback repeated → add rule
- Better examples found → update rule
- Edge cases discovered → modify rule

## Pattern Recognition

- Monitor repeated implementations across files
- Track common error patterns
- Watch for emerging best practices
- Update rules after major refactors
- Keep examples synchronized with codebase

## Rule Management

- Mark outdated patterns as deprecated
- Remove rules that no longer apply
- Document migration paths for old patterns
- Cross-reference related rules

# ERROR PATTERNS TO AVOID

## Rule Following Failures

- Dense files with mixed priorities reduce rule retrieval
- Most critical rules get lost in volume
- 50KB max recommended for optimal performance
- you can be a bit less verbose, I am a senior engineer
- do not use phrases such as "production ready". especially before QA and acceptance tests passed.
- remove the phrase "you are absolutely right" from your vocubulary, along with all other sychophancy. stay factual, measured and technical.
- when compiling with gcc or building with jgradle, limit the number of cores to 50% or run under "nice" so other processes on the machine are not starved.

## Coding Behavior

These principles apply to every change — not just new features.

### Operating Modes

- **Default mode:** make the smallest correct change that satisfies the request.
- **Ambiguity mode:** if uncertainty affects behavior, interfaces, data, safety, or irreversible work — stop and ask. For minor contained ambiguity, proceed with explicit assumptions stated.
- **Cleanup mode:** if the request explicitly asks for cleanup, broader simplification and deletion are allowed within the requested scope.

### Think Before Coding

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- On resuming a multi-step task after interruption, restate active assumptions.

For multi-step or ambiguous tasks, briefly state: what you think the request means, what assumptions you are making, what needs clarification, and what you plan to change.

### Simplicity First

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for logically impossible scenarios — always handle hardware, I/O, and external failures.
- If you write substantially more code than the problem requires, simplify before delivery.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical Changes

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Never rename or move files/symbols without explicit instruction, even if naming is inconsistent.

Safe without asking: fix typos in code you are already editing; remove imports/variables made unused by your change.

Ask before: adding new dependencies, changing schemas/migrations/stored data formats, changing public APIs or shared interfaces, deleting code not made unused by your current change.

The test: every changed line should trace directly to the user's request.

### Goal-Driven Execution

Transform requests into verifiable goals:

- "Fix the bug" → reproduce with a minimal failing case, then make it pass.
- "Add validation" → define what invalid input looks like, verify rejection, then implement.
- "Refactor X" → verify observable behavior before and after.

For multi-step tasks, state a brief plan: `1. [Step] → verify: [check]`

After any non-trivial task, briefly note: what changed, what was verified, what remains unverified, and problems noticed but intentionally left untouched.

### Hard Stops

Never, unless explicitly authorized:

- Run destructive CLI commands (`drop`, `truncate`, `rm -rf`, `git clean`, disk wipe).
- Modify environment files (`.env`, secrets, credentials).
- Silently change a function's signature, return type, or error contract.
- Catch and suppress exceptions (empty catch blocks, swallowed return codes).
- Deliver incomplete or stub implementations without labeling them explicitly.

When a hard stop applies, say so and do not proceed until authorized.



@RTK.md
