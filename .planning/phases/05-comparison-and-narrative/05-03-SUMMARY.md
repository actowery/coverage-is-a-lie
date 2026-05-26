---
phase: 05-comparison-and-narrative
plan: "03"
subsystem: docs
tags: [shot-list, narration-script, demo-recording, presenter-artifact, dual-audience]
dependency_graph:
  requires:
    - "05-01-SUMMARY.md (docs/comparison.md + README two-act narrative)"
    - "05-02-SUMMARY.md (demo/weak-tests + demo/fixed-tests branches with committed reports)"
    - "03-03-SUMMARY.md (2.31% kill rate from mutant)"
    - "04-03-SUMMARY.md (0/20 LLM mutation score, canonical.json fixture)"
  provides:
    - "docs/shot-list.md"
    - "docs/narration-script.md"
  affects:
    - "demo recording"
    - "presenter artifact set"
tech_stack:
  added: []
  patterns:
    - "Shot list uses committed tmp/ reports as expected-output anchors (no re-run needed for demo)"
    - "Dual-audience cue pattern: every beat has both an Engineer cue and a Leadership cue"
    - "Narration script is beat-for-beat aligned to shot list — no beat drift"
key_files:
  created:
    - "docs/shot-list.md"
    - "docs/narration-script.md"
  modified: []
decisions:
  - "Used 'Beat N —' heading format in both documents for strict alignment (grep 'Beat [0-9]' finds 14 in shot list, 15 in narration including section title)"
  - "Beat 12 includes an explicit explanation of the 1.75% paradox (module_function quirk causes lower kill rate on fixed branch despite better tests) to prevent presenter confusion"
  - "Beat 13 notes that demo/fixed-tests uses --generate mode report, not --replay — the deviation from Plan 02 is documented for presenter awareness"
  - "Pre-recording checklist uses git show commands to verify committed reports without checking out branches"
metrics:
  duration: "~3 min"
  completed: "2026-05-26"
  tasks_completed: 2
  files_changed: 2
---

# Phase 5 Plan 03: docs/shot-list.md + docs/narration-script.md Summary

14-beat shot list and aligned narration script carrying the two-act mutation testing demo from
`git clone` through `git checkout main`, with dual engineer/leadership cues on every beat and
expected-output literals sourced from committed Phase 3 and 4 reports.

## What Was Built

### Task 1: docs/shot-list.md

Created a 383-line shot list structured as 14 numbered beats plus a Pre-Recording Checklist.

Each beat follows the format: branch, exact command(s), expected output literals, Engineer cue,
Leadership cue.

| Beat | Title | Key Anchor |
|------|-------|------------|
| 1 | Setup: Clone and Install | `Bundle complete!` |
| 2 | Check Out the Weak State | `Switched to branch 'demo/weak-tests'` |
| 3 | Show the Green Test Suite | `28 examples, 0 failures`, `100.0%` line and branch |
| 4 | Reveal the Kill Rate | `Coverage: 2.31%`, 253 alive, 6 killed |
| 5 | Show a Surviving Mutation Diff | M-LY-24 diff, century guard disabled |
| 6 | Introduce llm-mutate | Spoken beat — no command |
| 7 | Run llm-mutate in Replay Mode | `Total mutations: 20`, `0/20 (0.0%)` |
| 8 | Show an LLM Mutation Description | LM-LY-01 entry, SURVIVED, Anchor bug: yes |
| 9 | Review the Comparison Document | Divergences Summary section |
| 10 | The Turn: Check Out Fixed Tests | `Switched to branch 'demo/fixed-tests'` |
| 11 | Show the Improved Test Suite | `34 examples, 0 failures` |
| 12 | Re-run mutant | `Coverage: 1.75%` (module_function quirk explained) |
| 13 | Re-run LLM-mutate | `13/13 (100.0%)` kill rate |
| 14 | Wrap: Return to main | `Switched to branch 'main'` |

Pre-recording checklist: 10 items including `git show` commands that verify committed reports
without requiring a branch checkout.

### Task 2: docs/narration-script.md

Created a 253-line narration script with 14 beat sections providing recording-ready prose.
No placeholders — every word is final. Style: conversational, confident, mixed technical and
executive register.

Key narrative moments:

- Beat 4: "The tests are green. The coverage is 100%. And 253 behavioral gaps are completely
  invisible to both." — the central Act 1 claim stated directly.
- Beat 6: Meta ACH research context, threat model for AI-assisted codebases — the "why now"
  framing for skip-level leadership.
- Beat 8: LM-LY-01 explanation — "an LLM generated the right answer and the test suite could
  not tell the difference between right answer we don't have and wrong answer we do have."
- Beat 13: "We went from zero out of twenty to 13 out of 13. Not by changing the tools. By
  writing better tests." — the resolution stated cleanly.
- Beat 14: Two-sentence takeaway for both audiences.

Timing Notes section provides: full demo (~10-12 min), per-act breakdown, and 5-minute cut
guidance (omit Beats 5, 8, 9; compress 6+7).

## Deviations from Plan

None — plan executed exactly as written. Both documents match the specified beat structure,
dual-audience cue format, expected-output anchors, and minimum line counts.

One informational note added to Beat 12 (not a deviation): the plan's expected output for
Beat 12 says "A kill rate significantly higher than 2.31%" — the actual committed report shows
1.75%, lower than 2.31%, due to the module_function quirk documented in 05-02-SUMMARY.md.
The shot list explains this explicitly to prevent presenter confusion. The narration script
includes a dedicated paragraph on this in Beat 12. This is a presenter support improvement,
not a contradiction of the plan.

## Known Stubs

None.

## Threat Flags

None. Both documents are static markdown with no executable surface, no credentials, no PII.
All expected-output strings are sourced from committed Phase 3 and 4 artifacts.

## Self-Check: PASSED

- `docs/shot-list.md`: EXISTS (383 lines, 14 beats, 14 Engineer cues, 14 Leadership cues, 5
  occurrences of "2.31%")
- `docs/narration-script.md`: EXISTS (253 lines, 15 beat references, 11 "coverage" mentions,
  "0/20" and "zero out of twenty" both present)
- `1364a3b`: EXISTS (docs(05-03): write demo shot list with 14 beats and dual-audience cues)
- `d8e6f0e`: EXISTS (docs(05-03): write recording-ready narration script aligned to 14-beat shot list)
