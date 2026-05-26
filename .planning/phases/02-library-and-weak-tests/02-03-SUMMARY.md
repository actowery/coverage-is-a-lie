---
phase: 02-library-and-weak-tests
plan: "03"
subsystem: ci
tags: [ruby, rspec, rakefile, github-actions, ci, mutation-testing]

requires:
  - phase: 02-library-and-weak-tests plan 01
    provides: lib/date_utils.rb, spec/spec_helper.rb, .rspec
  - phase: 02-library-and-weak-tests plan 02
    provides: spec/date_utils_spec.rb, 28-example suite at 100% line+branch coverage

provides:
  - Rakefile — rake spec default task via RSpec::Core::RakeTask
  - .github/workflows/ci.yml — rspec job added (bundle exec rspec, no COVERAGE env)
  - TEST-06 blind-review confirmation: suite is plausible first-pass coverage

affects:
  - 03-mutant-baseline (CI now runs rspec on every push; mutant job will be added to the same workflow)
  - All future phases (Rakefile is the local dev entry point for running specs)

tech-stack:
  added: []
  patterns:
    - "Separate CI jobs for bundle and rspec — preserves parallelism slot for Phase 3 mutant job"
    - "ruby-version: 3.4.9 explicit pin in ci.yml — avoids ruby/setup-ruby@v1 warning about ruby-version-file input (non-fatal but noisy)"
    - "No COVERAGE env in CI — SimpleCov minimum_coverage gate deliberately absent; CI tests correctness, not coverage level"
    - "bundle exec rake spec — Rakefile is the canonical local dev invocation"

key-files:
  created:
    - Rakefile
  modified:
    - .github/workflows/ci.yml

decisions:
  - "Keep bundle and rspec as separate CI jobs rather than merging — Phase 3 will add a mutant job alongside rspec, and separate jobs allow parallel execution"
  - "Use ruby-version: 3.4.9 explicit string rather than ruby-version-file: .ruby-version in ci.yml — fixes non-fatal warning from ruby/setup-ruby@v1 noted in Phase 1 follow-up"
  - "TEST-06 blind-review auto-approved (auto_mode active) — spec file reviewed against plausibility criteria: six describe blocks with realistic context groupings, real eq/be_truthy/be_falsy assertions, no suspiciously weak or obviously straw-man examples"

metrics:
  duration: "68 seconds"
  completed: "2026-05-26"
  tasks_completed: 3
  files_changed: 2
---

# Phase 2 Plan 03: CI Integration, Rakefile, and Blind Review Summary

CI wired to run `bundle exec rspec` on push/PR via dedicated rspec job; Rakefile provides `rake spec` as default local task; TEST-06 blind-review auto-approved confirming the 28-example suite looks like genuine first-pass coverage.

## What Was Built

### Task 1: Rakefile and CI workflow update

**Rakefile** (created at repo root):
- `require "rspec/core/rake_task"` — loads RakeTask DSL
- `RSpec::Core::RakeTask.new(:spec)` — defines `rake spec`
- `task default: :spec` — `bundle exec rake` runs the full spec suite

**CI workflow** (`.github/workflows/ci.yml` updated):
- Added `rspec` job alongside existing `bundle` job
- `bundle exec rspec` run step with no COVERAGE env variable
- `ruby-version: 3.4.9` explicit pin (fixes non-fatal ruby-version-file warning from Phase 1)
- Both jobs use `bundler-cache: true` for fast CI runs

### Task 2: Blind Review (checkpoint:human-verify, auto-approved)

Auto-approved under `workflow.auto_advance = true`. Plausibility assessment against TEST-06 criteria:

1. Does it look like genuine first-pass coverage? **YES** — six describe blocks mirroring the six functions, realistic `let` aliases, no placeholder descriptions.
2. Realistic test descriptions? **YES** — "returns 7 for a week apart", "skips the weekend when adding 3 days from Thursday", "returns false for 1900" — all domain-specific.
3. Multiple examples per function? **YES** — average 4-5 examples per describe block.
4. Context blocks suggesting developer thought about cases? **YES** — `context "when n is positive"`, `context "when birthday has already occurred this year"`, etc.
5. Any obviously weak/suspicious tests? **NO** — no `expect(result).to be_truthy` without domain meaning; no single-example describe blocks.

Result: **TEST-06 PASSED** — suite is plausible first-pass coverage.

### Task 3: Phase 2 commit

All Phase 2 source files were already committed individually in prior plan executions (02-01, 02-02 tasks). The atomic single-commit approach specified in the plan was not applicable at retry time — all six files already existed in git history with proper feat(02-01) and feat(02-02) commit messages. See Deviations section.

## Verification Results

All plan verification criteria confirmed passing:

| Check | Result |
|-------|--------|
| `bundle exec rspec` exits 0 | 28 examples, 0 failures |
| `COVERAGE=1 bundle exec rspec` exits 0 with 100% | Line 100.0% (27/27), Branch 100.0% (13/13) |
| `TZ=UTC COVERAGE=1 bundle exec rspec` exits 0 | PASS |
| `TZ=America/New_York bundle exec rspec` exits 0 | PASS |
| ci.yml contains rspec job with `bundle exec rspec` | PASS |
| Rakefile exists with RSpec::Core::RakeTask | PASS |
| Human reviewer confirmed plausible first-pass coverage | AUTO-APPROVED |

## Deviations from Plan

### Deviation 1: Task 3 atomic Phase 2 commit not executed

**Type:** Plan deviation (no rule violation — files already in correct state)

**Context:** This plan was a retry after an API overload. The prior execution had already completed Tasks 1 through 3 up to (but not including) the SUMMARY.md creation step. All six Phase 2 source files were already committed across prior plan commits (`feat(02-01)`, `feat(02-02)`, `feat(02-03)`).

**Impact:** None. All files are correctly committed and tracked in git history. The atomic "Phase 2" commit was a convenience wrapper that would have been redundant given the individual feat commits already in history.

**Files affected:** No action needed — all committed.

### Deviation 2: ruby-version-file warning fix (carried forward from Phase 1)

**Type:** Rule 1 (auto-fix — non-fatal but present CI warning)

**Found during:** Task 1 (CI update)

**Issue:** Phase 1 CI used `ruby-version-file: .ruby-version` which produces a non-fatal warning from `ruby/setup-ruby@v1` (noted in the follow-up note).

**Fix:** Changed both jobs to use `ruby-version: 3.4.9` explicit string, which is the documented correct input for this action version.

**Commit:** `8f6e24f`

## Phase 2 ROADMAP Success Criteria — Final Status

| Criterion | Status |
|-----------|--------|
| `bundle exec rspec` green + SimpleCov 100% line + branch | COMPLETE |
| Suite passes under TZ=UTC and TZ=America/New_York | COMPLETE |
| Blind review confirmed plausible first-pass coverage (TEST-06) | COMPLETE (auto-approved) |
| Every function contains an omitted boundary condition | COMPLETE (see lib/date_utils.rb inline comments) |

All four Phase 2 ROADMAP success criteria satisfied.

## Phase 3 Readiness

Phase 3 (mutant baseline) needs from this phase:

| Artifact | Location | Purpose |
|----------|----------|---------|
| `lib/date_utils.rb` | `/lib/date_utils.rb` | Mutant's analysis target — six functions, each with one intentional boundary bug |
| `spec/date_utils_spec.rb` | `/spec/date_utils_spec.rb` | Mutant's test harness — 28 examples, 100% coverage, will fail to kill ~6+ surviving mutants |
| `.github/workflows/ci.yml` | `.github/workflows/ci.yml` | Phase 3 will add a `mutant` job alongside the existing `rspec` job |
| `Gemfile.lock` | `Gemfile.lock` | Pins `mutant 0.16.3` and `mutant-rspec 0.16.3` — Phase 3 just needs to run them |
| `.mutant.yml` | `.mutant.yml` | Already configured (from Phase 1) with `--subject DateUtils` |

Phase 3 can begin immediately. Entry point: `.planning/phases/03-mutant-baseline/`.

## Key Commits

| Commit | Description | Files |
|--------|-------------|-------|
| `8f6e24f` | feat(02-03): add Rakefile and rspec job to CI workflow | Rakefile, .github/workflows/ci.yml |
| `1db068f` | feat(02-02): write weak RSpec suite with 100% line+branch coverage | spec/date_utils_spec.rb, lib/date_utils.rb |
| `33ac028` | feat(02-01): implement DateUtils library with six functions | lib/date_utils.rb |
| `9686451` | feat(02-01): add spec/spec_helper.rb and .rspec | spec/spec_helper.rb, .rspec |

## Known Stubs

None — all functions are implemented and returning real computed values. No hardcoded empty returns or placeholder text.

## Threat Flags

No new security-relevant surface introduced. CI job runs `bundle exec rspec` with no secrets or external API calls. `GITHUB_TOKEN` default read-only scope is sufficient.

## Self-Check

- [x] Rakefile exists at `/Users/adrian.towery/Projects/mutation-testing-example/Rakefile`
- [x] ci.yml contains `bundle exec rspec` run step
- [x] `bundle exec rake spec` exits 0 (28 examples, 0 failures)
- [x] `COVERAGE=1 bundle exec rspec` shows 100% line and branch
- [x] Commit `8f6e24f` exists in git log
- [x] All Phase 2 success criteria met
