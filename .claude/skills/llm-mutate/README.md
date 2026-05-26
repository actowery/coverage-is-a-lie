# llm-mutate skill

## What It Does

LLM-driven mutation testing that generates semantically meaningful mutations for `lib/date_utils.rb`, validates each with `ruby -c`, runs the RSpec suite, and produces `tmp/llm-mutation-report.md`. Complements the `mutant` gem baseline by targeting semantic boundary bugs — off-by-one DST transitions, wrong leap-year conditions, incorrect sign for negative durations — rather than exhaustive operator substitutions. Inspired by Meta's ACH research ("what a careless developer would write").

## Two Modes

### --replay (recommended for demo)

Reads the committed fixture at `.claude/skills/llm-mutate/fixtures/canonical.json`. Deterministic — produces identical output on any machine with no LLM calls.

Invoke: `/llm-mutate --replay`

### --generate (development / regeneration)

Instructs Claude to read `lib/date_utils.rb` and generate up to `MAX_MUTATIONS` (default 20) new mutations live in the current Claude Code session. Updates `tmp/generated/` with new mutation files and writes `tmp/llm-mutation-report.md`.

Invoke: `/llm-mutate --generate`

## Requirements

- Ruby 3.4.x with bundler
- `.claude/skills/llm-mutate/scripts/run_mutant_spec.sh` (included)
- Invoked inside a Claude Code session (no external API key needed)

## Output

`tmp/llm-mutation-report.md` — mutation score, per-function breakdown, per-mutation rows with plain-English description, diff, and kill/survive verdict.
