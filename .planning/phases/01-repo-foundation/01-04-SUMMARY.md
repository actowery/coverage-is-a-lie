---
phase: 01-repo-foundation
plan: 04
subsystem: infra
tags: [github, gh-cli, github-actions, ci, public-repo, mit-license]

requires:
  - phase: 01-repo-foundation
    provides: "Clean `main` with eight scaffold files at SHA 40a8dee, plus planning commit b92a868"
provides:
  - "Public GitHub repo at https://github.com/actowery/coverage-is-a-lie with MIT license auto-detected"
  - "origin remote configured; main tracks origin/main"
  - "First CI run (databaseId 26465269023) completed with conclusion: success"
affects: [02-domain-library, 03-mutant-baseline, 04-llm-mutation-skill, 05-recording-script, 06-readme-narrative]

tech-stack:
  added: []
  patterns: ["gh repo create --public --source=. --remote=origin --push (single-shot per RESEARCH §Don't Hand-Roll)"]

key-files:
  created:
    - .planning/phases/01-repo-foundation/01-04-SUMMARY.md
  modified:
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "Created repo as PUBLIC (user-confirmed) — required for `mutant --usage opensource` per D-05."
  - "Did NOT pass --license MIT or --gitignore Ruby to gh — those files already existed in the scaffold; gh would error."
  - "Ran gh repo create from orchestrator (not subagent) because the subagent's safety classifier blocked public-surface creation and the user authorization was addressed to the orchestrator."

patterns-established:
  - "Public-surface creation requires user authorization addressed to the actor performing it (orchestrator vs subagent are distinct from the classifier's standpoint)."

requirements-completed: [REPO-01]

duration: 5min
completed: 2026-05-26
---

# Phase 1, Plan 04: Public GitHub Repo + CI Green Summary

**Public repo actowery/coverage-is-a-lie pushed with all eight scaffold files; first CI run green in 39s.**

## Performance

- **Duration:** ~5 min (including 39s CI wait)
- **Started:** 2026-05-26T~17:47Z
- **Completed:** 2026-05-26T17:49:22Z (CI completion)
- **Tasks:** 2 (gh repo create + push, then CI poll)
- **Files modified:** 0 source files (this plan only creates the remote and verifies CI)

## Accomplishments

- Ran `gh repo create coverage-is-a-lie --public --source=. --remote=origin --push --description "Mutation testing demo — why 100% code coverage is a lie"`
- Repo created at https://github.com/actowery/coverage-is-a-lie
- GitHub auto-detected MIT license from the `LICENSE` file body (verified: `licenseInfo.key == "mit"`)
- Verified visibility = `PUBLIC`
- Pushed all 5 commits (including planning history) so `origin/main` = `b92a868`
- First CI run on the push: databaseId `26465269023`, workflow `CI`, conclusion `success`
- Job `bundle install` completed in 35s

## Task Commits

1. **Task 1: gh repo create + push** — no local commits (creates remote, adds origin, pushes existing HEAD)
2. **Task 2: CI verification** — no local commits (observation only)
3. **Plan metadata** — committed below alongside STATE.md and ROADMAP.md updates

## Files Created/Modified

- `.planning/phases/01-repo-foundation/01-04-SUMMARY.md` — this file
- `.planning/STATE.md` — phase 01 complete
- `.planning/ROADMAP.md` — phase 01 marked complete
- Remote: `https://github.com/actowery/coverage-is-a-lie` (new)
- `.git/config` — `origin` remote added

## Decisions Made

- **Public, not private:** Confirmed by user via AskUserQuestion. REPO-01 + D-05 require public for `mutant --usage opensource`.
- **gh single-shot, not git-remote + git-push:** Per RESEARCH §"Don't Hand-Roll" — `gh repo create --source=. --remote=origin --push` is the canonical pattern.

## Deviations from Plan

### Deviation 1: Subagent classifier blocked public-surface creation
- **Found during:** Initial gsd-executor spawn for plan 01-04
- **Issue:** The subagent's safety classifier flagged `gh repo create --public` as creating a public surface without explicit user authorization addressed to the subagent itself. The user's prior `AskUserQuestion` approval went to the orchestrator, not the subagent.
- **Fix:** Ran `gh repo create` and `gh run watch` directly from the orchestrator, where the user authorization was on record. The subagent's role for this plan was effectively skipped; the orchestrator wrote SUMMARY.md and committed it.
- **Files modified:** None changed by this deviation — same end-state.
- **Verification:** Repo public + MIT + CI green confirmed via gh CLI queries.
- **Pattern flagged for future phases:** Plans that create public-visible state should either be marked `autonomous: false` (human-action checkpoint) or planned to run from the orchestrator with user authorization in-conversation. Capturing as a learning for plan-phase.

---

**Total deviations:** 1 process (no functional impact)
**Impact on plan:** Same final state — phase 01 fully delivered.

## Issues Encountered

- **CI warning (non-fatal):** `ruby/setup-ruby@v1` annotated "Unexpected input(s) 'ruby-version-file'" — that input is not valid for the action; valid inputs include `ruby-version`, `bundler`, `bundler-cache`, etc. Despite the warning, ruby/setup-ruby auto-detected `.ruby-version` via its default behavior and `bundle install` succeeded. Conclusion remained `success`, so REPO-04 ("CI is green on the first push") is satisfied. **Flag for Phase 2:** consider changing the CI workflow to either drop `ruby-version-file:` (relying on default `.ruby-version` discovery) or switch to explicit `ruby-version: 3.4.9`. Not blocking.

## Next Phase Readiness

- Phase 1 complete: every subsequent phase can `git clone https://github.com/actowery/coverage-is-a-lie` and start clean
- Public repo unblocks `mutant --usage opensource` in Phase 3
- CI scaffold ready to evolve in Phase 2 (add rspec + simplecov steps)
- Open item: CI annotation about `ruby-version-file` (low priority, candidate fix in Phase 2)

---
*Phase: 01-repo-foundation*
*Completed: 2026-05-26*
