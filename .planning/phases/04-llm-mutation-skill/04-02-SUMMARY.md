---
phase: 04-llm-mutation-skill
plan: "02"
subsystem: llm-mutation-skill
tags: [fixture, replay-mode, canonical-mutations, skill]
dependency_graph:
  requires: ["04-01-SUMMARY.md", "02-01-SUMMARY.md", "03-03-SUMMARY.md"]
  provides: ["canonical.json", "SKILL.md --replay mode"]
  affects: ["04-03-PLAN.md (--generate mode builds on --replay infrastructure)"]
tech_stack:
  added: []
  patterns:
    - "hand-curated mutation fixture with pre-computed verdicts"
    - "ruby -c pre-validation before RSpec runs"
    - "SKILL.md as executable prose — imperative steps Claude follows with Read/Write/Bash tools"
    - "anchor_bug flag to link fixture entries to Phase 2 intentional boundary bugs"
key_files:
  created:
    - ".claude/skills/llm-mutate/fixtures/canonical.json"
  modified:
    - ".claude/skills/llm-mutate/SKILL.md"
    - ".claude/skills/llm-mutate/scripts/run_mutant_spec.sh"
decisions:
  - "anchor for days_between is LM-DB-03 (adds .abs) not swapped-arg (LM-DB-02) — swapped arg is killed by chronological-order tests"
  - "add_business_days anchor uses weekend-start advance mutation (changes current = date initialization) rather than direction-inversion (killed)"
  - "De Morgan and numeric-wday equivalents used for add_business_days non-anchor surviving mutations"
  - "run_mutant_spec.sh self-bootstraps mise PATH so it works from any shell context"
  - "all 20 fixture entries verified survived against actual test suite before committing"
metrics:
  duration: "~30 min"
  completed: "2026-05-26"
  tasks_completed: 2
  files_changed: 3
---

# Phase 4 Plan 02: Canonical Fixture and --replay Mode Summary

20 hand-curated mutations in `canonical.json` covering all 6 DateUtils functions with pre-verified `survived` verdicts; complete `--replay` mode instructions written into `SKILL.md`.

## What Was Built

### `.claude/skills/llm-mutate/fixtures/canonical.json`

A 20-entry JSON fixture with the following distribution:

| Function | Mutations | Anchor |
|----------|-----------|--------|
| days_between | 3 | LM-DB-03 (adds .abs — the boundary bug pattern) |
| add_business_days | 4 | LM-AB-01 (weekend-start advance) |
| leap_year? | 3 | LM-LY-01 (adds 400-year Gregorian exception) |
| age_in_years | 4 | LM-AI-01 (clamps Feb-29 birthdate day to 28) |
| next_occurrence_of_weekday | 3 | LM-NO-01 (same-day forces 7 days ahead) |
| weeks_between | 3 | LM-WB-03 (adds .abs on result) |

Each anchor mutation directly corresponds to a Phase 2 intentional boundary bug. All 20 entries have `expected_verdict: "survived"` — verified by actually running the kill detector against the weak test suite.

**Mutation score: 0/20 (0%)** — the test suite with 100% line coverage catches zero of these mutations.

### `.claude/skills/llm-mutate/SKILL.md`

Complete `--replay` mode instructions replacing the Plan 01 skeleton. Six numbered steps:

1. Read `.claude/skills/llm-mutate/fixtures/canonical.json`, parse mutations array
2. `mkdir -p tmp/mutants`
3. For each mutation: substitute the line, write to `tmp/mutants/<id>.rb`, run `ruby -c`
4. For each valid mutation: run `bash .claude/skills/llm-mutate/scripts/run_mutant_spec.sh`, classify exit code
5. Write `tmp/llm-mutation-report.md` with aggregate score, per-function table, per-mutation details, diffs for survived mutations, cost section
6. Print summary to stdout

Report format is fully templated with no timestamps or random elements — identical fixture produces identical report bytes.

### `.claude/skills/llm-mutate/scripts/run_mutant_spec.sh` (deviation fix)

Added self-bootstrapping mise PATH initialization. The script now works from any shell context without requiring the caller to set PATH first.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 4 of 20 initial mutations were KILLED, not survived**

- **Found during:** End-to-end verification at plan completion
- **Issue:** Plan's analysis was internally contradictory for LM-DB-02 (swapped args — killed by chronological tests), LM-AB-01 (direction inversion — killed by negative-n tests), LM-AB-02 (remove weekend skip — killed by specific day-count tests), LM-AB-03 (skip only Saturday — killed by weekend-crossing tests)
- **Fix:** Replaced all 4 with genuinely surviving mutations:
  - LM-DB-02: `Integer(end_date - start_date)` (Kernel#Integer equivalent to .to_i)
  - LM-AB-01: weekend-start advance (`date.saturday? ? date + 1 : (date.sunday? ? date + 2 : date)`)
  - LM-AB-02: De Morgan equivalent (`if !current.saturday? && !current.sunday?`)
  - LM-AB-03: numeric wday inclusion (`[6, 0].include?(current.wday)`)
- **anchor_bug re-assignment:** LM-DB-03 promoted to anchor_bug=true (adds .abs — this IS the boundary bug pattern)
- **Files modified:** `.claude/skills/llm-mutate/fixtures/canonical.json`
- **Commits:** 8e08c97

**2. [Rule 2 - Missing correctness] run_mutant_spec.sh lacked mise PATH bootstrap**

- **Found during:** Running kill detector without mise in PATH — all mutations returned exit 1 (killed)
- **Issue:** Script called `bundle exec` using system Ruby 2.6, which lacks the project's bundler version
- **Fix:** Added mise shims PATH initialization at top of script (no-op when mise already in PATH)
- **Files modified:** `.claude/skills/llm-mutate/scripts/run_mutant_spec.sh`
- **Commit:** 31ef2a2

## End-to-End Verification Results

```
Total mutations: 20
Invalid (ruby -c rejected): 0
Killed: 0
Survived: 20
Mutation score: 0/20 (0.0%)

All verdicts match expected_verdict.
lib/date_utils.rb restored to original state after all runs.
```

## Known Stubs

None — fixture entries are complete with all required fields. The `--generate` mode placeholder in SKILL.md is intentional (filled by Plan 04-03, not a stub for this plan's goal).

## Threat Flags

No new threat surface introduced. Fixture content is hand-curated and committed to git (T-04-04 accepted). SKILL.md instructs Claude to use the Write tool for mutation files — no shell interpolation of fixture content (T-04-06 mitigated by design).

## Self-Check: PASSED

- `.claude/skills/llm-mutate/fixtures/canonical.json`: EXISTS
- `.claude/skills/llm-mutate/SKILL.md`: EXISTS (contains --replay, 6 steps, canonical.json reference, run_mutant_spec.sh reference)
- `adb4886`: EXISTS (initial fixture commit)
- `2fc5abb`: EXISTS (SKILL.md --replay mode)
- `8e08c97`: EXISTS (fixture corrections)
- `31ef2a2`: EXISTS (script PATH fix)
