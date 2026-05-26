---
phase: 06-end-to-end-validation
plan: 01
subsystem: testing
tags: [mutation-testing, rspec, ruby, demo, smoke-test, determinism]

requires:
  - phase: 05-comparison-and-narrative
    provides: "demo branches (demo/weak-tests, demo/fixed-tests), shot-list.md, narration-script.md, comparison.md"

provides:
  - "All 14 demo shot-list beats verified with actual output vs expected anchors"
  - "Beat 5 grep command corrected to produce visible output (M-LY-* IDs don't exist in mutant report)"
  - "Three-run determinism check: verdict pipeline md5 matches across all three runs"
  - "Fresh clone smoke test: bundle install + rspec pass from cold clone"
  - "DEMO READY verdict"

affects: [demo-recording, README]

tech-stack:
  added: []
  patterns: ["Replay pipeline: fixture-driven deterministic RSpec kill-detection"]

key-files:
  created:
    - ".planning/phases/06-end-to-end-validation/06-01-SUMMARY.md"
  modified:
    - "docs/shot-list.md"

key-decisions:
  - "Beat 5 command fixed: mutant uses internal hash IDs (evil:<function>:<file>:<hash>), not M-LY-* labels from audit doc; grep on leap_year? function name produces a working diff"
  - "Beat 9 LM-WB ID corrected: float division mutation is LM-WB-01, not LM-WB-02 as previously documented"
  - "Determinism verified via kill-verdict pipeline (3 runs, identical md5), not full report regeneration (report content includes full descriptions from fixture which are already static)"

patterns-established:
  - "Shot list verification: run each command verbatim, grep for every anchor string before marking beat as pass"

requirements-completed: [VAL-01, VAL-02, VAL-03]

duration: 5min
completed: 2026-05-26
---

# Phase 6 Plan 01: End-to-End Validation Summary

**Full two-act demo validated across all 14 shot-list beats with two drift fixes; three-run determinism check passes; fresh clone runs cleanly — demo is READY**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-26T19:52:19Z
- **Completed:** 2026-05-26T19:56:37Z
- **Tasks:** 3
- **Files modified:** 1 (docs/shot-list.md)

## Accomplishments

- All 14 shot-list beats verified; 12 passed as-written, 2 required fixes (Beats 5 and 9)
- Three consecutive replay pipeline runs produced identical md5 hashes (`16e8994bb5621e0edbcf0ba63f4138ed`)
- Fresh clone into /tmp/coverage-fresh completed bundle install and rspec cleanly (28 examples, 0 failures on main branch)
- Pre-recording checklist passes: all three git-show anchor greps confirmed

## Beat-by-Beat Results Table

| Beat | Name | Command / Check | Expected Anchor | Actual Output | Status |
|------|------|-----------------|-----------------|---------------|--------|
| 1 | Setup: Clone and Install | `git clone` + `bundle install` | `Bundle complete!` | `Bundle complete! 5 Gemfile dependencies, 33 gems now installed.` | PASS |
| 2 | Check Out Weak State | `git checkout demo/weak-tests` | `Switched to branch 'demo/weak-tests'` | `Switched to branch 'demo/weak-tests'` | PASS |
| 3 | Show Green Test Suite | `COVERAGE=1 bundle exec rspec` | `28 examples, 0 failures`, `Line Coverage: 100.0%`, `Branch Coverage: 100.0%` | All three present | PASS |
| 4 | Reveal Kill Rate | `cat tmp/mutant-report.txt` | `Coverage: 2.31%`, `Kills: 6`, `Alive: 253` | All three present | PASS |
| 5 | Show Surviving Mutation Diff | ~~`grep -A 10 "M-LY-24\|M-LY-26"`~~ → **FIXED** `grep -A 15 "leap_year?"` | Diff showing century-guard removed, marked alive | `evil:DateUtils#leap_year?:...:20ad8` with diff removing `% 100` guard | FIXED + PASS |
| 6 | Introduce llm-mutate | `cat docs/comparison.md | head -20` | File non-empty | Non-empty, 8 divergences found | PASS |
| 7 | Run llm-mutate Replay Mode | `cat tmp/llm-mutation-report.md` | `Total mutations: 20`, `Survived: 20`, `Mutation score: 0/20 (0.0%)`, `Mode: --replay (deterministic)` | All four present | PASS |
| 8 | Show LLM Mutation Description | `grep -A 12 "LM-LY-01" tmp/llm-mutation-report.md` | `LM-LY-01`, `leap_year?`, `Adds the correct 400-year Gregorian exception`, `SURVIVED`, `Anchor bug: yes` | All five present | PASS |
| 9 | Review Comparison Document | `cat docs/comparison.md` | `add_business_days` row, `LM-AB-01`, `LM-WB-01` or `LM-WB-02`, 3+ divergences | `LM-AB-01` present, `LM-WB-01` present (engineer cue previously said LM-WB-02 — **FIXED**), 8 divergences total | FIXED + PASS |
| 10 | Check Out Fixed Tests | `git checkout demo/fixed-tests` | `Switched to branch 'demo/fixed-tests'` | `Switched to branch 'demo/fixed-tests'` | PASS |
| 11 | Show Improved Test Suite | `COVERAGE=1 bundle exec rspec` | `34 examples, 0 failures`, `Line Coverage: 100.0%` | `34 examples, 0 failures`, `Line Coverage: 100.0%`, `Branch Coverage: 100.0%` | PASS |
| 12 | Re-run mutant | `cat tmp/mutant-report.txt` | `Coverage: 1.75%` | `Coverage: 1.75%` | PASS |
| 13 | Re-run LLM-mutate | `cat tmp/llm-mutation-report.md` | `Total mutations: 13`, `Killed: 13`, `Mutation score: 13/13 (100.0%)`, `Mode: --generate` | All four present | PASS |
| 14 | Wrap: Return to main | `git checkout main` | `Switched to branch 'main'` | `Switched to branch 'main'` | PASS |

## Pre-Recording Checklist Results

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| `git show demo/weak-tests:tmp/mutant-report.txt \| grep Coverage` | `2.31%` | `Coverage: 2.31%` | PASS |
| `git show demo/weak-tests:tmp/llm-mutation-report.md \| grep "Mutation score"` | `0/20 (0.0%)` | `**Mutation score:** 0/20 (0.0%)` | PASS |
| `git show demo/fixed-tests:tmp/llm-mutation-report.md \| grep "Mutation score"` | `13/13 (100.0%)` | `**Mutation score:** 13/13 (100.0%)` | PASS |

## Task Commits

1. **Task 1: Walk all 14 shot-list beats and fix drift** - `02a76e9` (fix)
2. **Task 2: Determinism check** - No code commit (verification-only task; verdicts confirmed stable, no report changes needed)
3. **Task 3: Fresh-clone smoke test and SUMMARY** - included in plan metadata commit

**Plan metadata:** (docs commit to follow)

## Determinism Check Results (Task 2)

Three consecutive replay pipeline executions on `demo/weak-tests`:

| Run | Verdict hash (md5 of 20 mutation verdicts) |
|-----|-------------------------------------------|
| Run 1 | `16e8994bb5621e0edbcf0ba63f4138ed` |
| Run 2 | `16e8994bb5621e0edbcf0ba63f4138ed` |
| Run 3 | `16e8994bb5621e0edbcf0ba63f4138ed` |

**Result: IDENTICAL - VAL-03 satisfied**

All 20 mutations survived in every run. The committed `tmp/llm-mutation-report.md` md5:
`9f87c89a0df41dfeac0dfdaa4d1dfd57` (read three times, identical).

The SKILL.md determinism guarantee holds: no timestamps, no random elements, fixture-driven pipeline.

## Fresh Clone Smoke Test Results (Task 3)

| Step | Command | Expected | Actual | Status |
|------|---------|----------|--------|--------|
| Clone | `git clone https://github.com/actowery/coverage-is-a-lie /tmp/coverage-fresh` | Exit 0 | Exit 0 | PASS |
| Bundle install | `cd /tmp/coverage-fresh && bundle install` | `Bundle complete!` | `Bundle complete! 5 Gemfile dependencies, 33 gems now installed.` | PASS |
| RSpec | `bundle exec rspec` | `28 examples, 0 failures` | `28 examples, 0 failures` | PASS |
| Skill file | `ls /tmp/coverage-fresh/.claude/skills/llm-mutate/SKILL.md` | File listed | File listed | PASS |
| Demo branches | `git ls-remote --heads origin demo/weak-tests demo/fixed-tests` | Two refs listed | Two refs listed | PASS |
| Cleanup | `rm -rf /tmp/coverage-fresh` | Done | Done | PASS |

## Files Created/Modified

- `docs/shot-list.md` - Two drift fixes: Beat 5 command corrected, Beat 9 LM-WB ID corrected
- `.planning/phases/06-end-to-end-validation/06-01-SUMMARY.md` - This file

## Decisions Made

- Beat 5: The primary command `grep -A 10 "M-LY-24\|M-LY-26" tmp/mutant-report.txt` was replaced with `grep -A 15 "leap_year?"` because mutant uses internal hash IDs (e.g., `evil:DateUtils#leap_year?:...:<hash>`), not the M-LY-* labels from `docs/mutant-audit.md`. The new command produces a visible surviving mutation diff.
- Beat 9: Engineer cue updated from `LM-WB-02` to `LM-WB-01` because the float division mutation in the committed report is `LM-WB-01`. `LM-WB-02` is the "inline date subtraction" mutation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Beat 5 grep command referenced non-existent IDs in mutant report**
- **Found during:** Task 1 (Beat 5 verification)
- **Issue:** `grep -A 10 "M-LY-24\|M-LY-26" tmp/mutant-report.txt` returns empty output because the mutant tool uses internal hash-based IDs, not the M-LY-* labels assigned in `docs/mutant-audit.md`. Running this command during the demo would show a blank terminal.
- **Fix:** Replaced with `grep -A 15 "leap_year?" tmp/mutant-report.txt | head -25` which shows the actual surviving mutation diff for the leap_year? function with the `evil:` alive marker.
- **Files modified:** `docs/shot-list.md`
- **Verification:** New command produces 25 lines showing `evil:DateUtils#leap_year?:...:20ad8` with diff
- **Committed in:** `02a76e9`

**2. [Rule 1 - Bug] Beat 9 engineer cue referenced wrong LM-WB ID for float division**
- **Found during:** Task 1 (Beat 9 verification)
- **Issue:** Engineer cue said "Also note LM-WB-02: float division coercion (`/ 7.0`)" but `LM-WB-01` is the float division mutation and `LM-WB-02` is the "inline date subtraction" mutation. A presenter pointing to `LM-WB-02` in the report would find the wrong mutation.
- **Fix:** Updated engineer cue from `LM-WB-02` to `LM-WB-01`.
- **Files modified:** `docs/shot-list.md`
- **Verification:** `LM-WB-01` entry in `tmp/llm-mutation-report.md` confirms `/ 7.0` float division description
- **Committed in:** `02a76e9`

---

**Total deviations:** 2 auto-fixed (both Rule 1 - documentation bug)
**Impact on plan:** Both fixes essential for demo correctness. No scope creep.

## Issues Encountered

- Stash was temporarily used to handle `docs/shot-list.md` being tracked on demo branches during checkout, but stash was immediately popped and changes were staged and committed on main. No data lost.

## Final Verdict

**DEMO READY**

All 14 beats produce the documented expected output (with two fixes applied to shot-list.md). The replay pipeline is deterministic. The repo bootstraps cleanly from a fresh clone. Pre-recording checklist passes.

## Next Phase Readiness

This is the final validation phase. The demo is ready for recording. All VAL requirements satisfied:
- VAL-01: Full two-act demo runs end-to-end without errors — SATISFIED
- VAL-02: Every shot-list command copy-pasteable and produces documented output — SATISFIED (after fixes)
- VAL-03: Three consecutive --replay runs produce identical results — SATISFIED

---
*Phase: 06-end-to-end-validation*
*Completed: 2026-05-26*
