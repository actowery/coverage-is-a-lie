# Phase 4: LLM Mutation Skill - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

Build `/llm-mutate` as a pure Claude Code skill (no SDK, no API key, no external client). Two modes:

- `--generate`: Claude (the current session model) generates mutations live, validates them with `ruby -c`, runs them through an RSpec wrapper, classifies killed/survived, writes `tmp/llm-mutation-report.md`.
- `--replay`: Reads a committed fixture (`fixtures/llm-mutation-fixture.json` or similar) and reproduces the canonical demo output identically on any machine. **The demo always uses --replay** for reproducibility.

**Requirements:** SKILL-01..11
**Success Criteria:**
1. `--replay` produces identical output across three runs
2. `--generate` respects MAX_MUTATIONS cap (default 20), logs estimated token usage and cost
3. Report covers all six DateUtils functions with description+diff+verdict
4. `ruby -c` rejects non-compilable mutations with logged count
5. Skill invokable as `/llm-mutate` inside Claude Code without manual file editing
</domain>

<decisions>
## Implementation Decisions

### Architecture (locked by REQUIREMENTS.md SKILL-03)
- **Pure SKILL.md instructions** — no Ruby gems beyond the existing test stack. The skill is markdown that instructs Claude to use Read/Write/Bash tools.
- **No `anthropic` gem.** PROJECT.md history: "docs: drop anthropic SDK from skill — runs inside Claude Code session, no API key needed"
- **`scripts/run_mutant_spec.sh` is the kill detector** — wraps RSpec with the right exit semantics (exit 0 = killed = good, exit 1 = survived = bad).
- **Fixture replay is canonical** — the demo always runs `/llm-mutate --replay`; live generation is for development/regeneration only.

### Open choices for planner
- Fixture file format (JSON / YAML / per-mutation .rb files in fixtures/)
- Exact MAX_MUTATIONS distribution (e.g., 20 ÷ 6 functions = ~3 mutations per function)
- Cost estimation method (input bytes × $3/MTok input, output bytes × $15/MTok for Sonnet 4.6)
- Whether `--generate` updates the committed fixture or writes to a separate workspace
</decisions>

<code_context>
- Phase 2 boundary bugs are documented in 02-01-SUMMARY.md — the LLM-driven mutations should *also* surface these (semantic-bug mutations beat exhaustive operator mutations per Meta ACH)
- Phase 3 `tmp/mutant-report.txt` is the baseline for comparison (Phase 5 will diff the two)
- `lib/date_utils.rb` is the subject; `spec/date_utils_spec.rb` is the test suite
- Phase 1 created `.gitignore` excluding `tmp/`; fixture must NOT live under `tmp/`
- Phase 1 CLAUDE.md skill packaging section documents `.claude/skills/<name>/SKILL.md` layout
</code_context>

<specifics>
## Specific Ideas
- Fixture lives at `.claude/skills/llm-mutate/fixtures/<name>.{json|yaml}` (or similar — committed, not gitignored)
- Mutation IDs use a stable naming scheme (e.g., `LM-DB-01` for "LLM-Mutation, days_between, #01") so fixture replay is deterministic
- Plain-English description per mutation per Meta ACH style ("what a careless developer would write")
- Per-mutation lifecycle: generate description → produce diff → write to tmp/mutants/<id>.rb → ruby -c validate → run RSpec wrapper → classify → record
- Output report: mutation score (killed / total), per-function breakdown, then per-mutation rows
- Estimated cost: input/output token approximation × Sonnet 4.6 rates ($3/$15 per MTok)
</specifics>

<deferred>
## Deferred Ideas
- SKILL-V2-* future enhancements (coverage-gap targeting, configurable cap, equivalence detection, CI integration) — explicitly future-only per REQUIREMENTS.md
</deferred>
