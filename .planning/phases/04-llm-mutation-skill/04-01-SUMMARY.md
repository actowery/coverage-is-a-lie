---
phase: 04-llm-mutation-skill
plan: 01
subsystem: testing
tags: [mutation-testing, bash, claude-code-skill, rspec, llm-mutate]

# Dependency graph
requires:
  - phase: 03-mutant-baseline
    provides: spec/date_utils_spec.rb and spec/spec_helper.rb with Timeout guard enabling safe RSpec subprocess execution
  - phase: 01-repo-foundation
    provides: lib/date_utils.rb as the mutation target subject
provides:
  - .claude/skills/llm-mutate/SKILL.md with valid frontmatter (name, description, disable-model-invocation)
  - .claude/skills/llm-mutate/scripts/run_mutant_spec.sh kill detector with trap/restore semantics
  - .claude/skills/llm-mutate/README.md operator guide for two modes
  - .claude/skills/llm-mutate/{scripts,fixtures,tmp} directory scaffold
  - .gitignore entry for .claude/skills/llm-mutate/tmp/ preventing workspace files from reaching the index
affects:
  - 04-02 (replay mode implementation — depends on SKILL.md skeleton and run_mutant_spec.sh)
  - 04-03 (generate mode implementation — depends on same foundations)
  - 05-demo-narrative (depends on skill being invokable as /llm-mutate)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Kill-detector pattern: backup original → trap EXIT to restore → install mutant → run RSpec → exit with RSpec code"
    - "Claude Code skill skeleton: SKILL.md frontmatter + section headers as contracts for downstream plans"

key-files:
  created:
    - .claude/skills/llm-mutate/SKILL.md
    - .claude/skills/llm-mutate/scripts/run_mutant_spec.sh
    - .claude/skills/llm-mutate/README.md
  modified:
    - .gitignore

key-decisions:
  - "EXIT trap in run_mutant_spec.sh guarantees lib/date_utils.rb restore on crash, SIGINT, and set -e termination (T-04-01 mitigation)"
  - "Script suppresses RSpec output (> /dev/null 2>&1) for clean batch operation; report rendering reads verdicts not RSpec output"
  - "SKILL.md skeleton frontmatter is final and must not be changed by Plans 02/03; only body sections are filled in"
  - "tmp/ directory created at runtime by script (mkdir -p) so no empty directory commit needed in git"

patterns-established:
  - "Kill-detector invocation: bash .claude/skills/llm-mutate/scripts/run_mutant_spec.sh <mutant_file>"
  - "Exit semantics: exit 0 = mutation killed (RSpec passed); exit non-zero = mutation survived (RSpec failed)"

requirements-completed: [SKILL-01, SKILL-03, SKILL-11]

# Metrics
duration: 2min
completed: 2026-05-26
---

# Phase 4 Plan 01: LLM Mutation Skill Summary

**Bash kill-detector with EXIT trap/restore semantics, SKILL.md skeleton with valid frontmatter, and .gitignore protection for workspace files**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-26T18:50:48Z
- **Completed:** 2026-05-26T18:52:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `run_mutant_spec.sh` kill detector: backs up `lib/date_utils.rb`, registers EXIT trap to always restore (even on crash/SIGINT), installs mutant, runs `bundle exec rspec spec/date_utils_spec.rb`, exits with RSpec exit code
- `SKILL.md` skeleton with final frontmatter (`name: llm-mutate`, `description`, `disable-model-invocation: false`) and placeholder section headers for Plans 02 and 03 to fill
- `README.md` operator guide documenting `--replay` (deterministic, no LLM calls) and `--generate` (live LLM session) modes with requirements and output path
- `.gitignore` updated to exclude `.claude/skills/llm-mutate/tmp/` workspace files from index
- Smoke test confirmed: trivially broken mutant causes exit 1 (killed), `lib/date_utils.rb` restored identically after run

## Task Commits

Each task was committed atomically:

1. **Task 1: Create run_mutant_spec.sh kill detector and directory scaffold** - `a1889d3` (feat)
2. **Task 2: Write SKILL.md skeleton, README.md, and update .gitignore** - `307d776` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified
- `.claude/skills/llm-mutate/scripts/run_mutant_spec.sh` - Kill detector: backup → trap → install mutant → run RSpec → restore on exit
- `.claude/skills/llm-mutate/SKILL.md` - Skill entry point with final frontmatter; skeleton sections for Plans 02/03
- `.claude/skills/llm-mutate/README.md` - Operator guide: what the skill does, two invocation modes, requirements, output
- `.gitignore` - Appended `.claude/skills/llm-mutate/tmp/` entry

## Decisions Made
- EXIT trap chosen over manual cleanup calls: fires on `set -e` termination, SIGINT, SIGTERM, and normal exit — guarantees restore in all failure modes (T-04-01 mitigation from threat model)
- RSpec output suppressed to `/dev/null` in the script for clean batch operation; downstream report rendering reads kill/survive verdicts, not raw RSpec output
- SKILL.md frontmatter marked as final — Plans 02 and 03 fill in body sections only, never change the `name`, `description`, or `disable-model-invocation` fields
- `tmp/` directory created at runtime via `mkdir -p` in the script; empty directories are not committed to git

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- `run_mutant_spec.sh` is ready for Plan 04-02 replay implementation to invoke
- SKILL.md skeleton provides the `name: llm-mutate` invocation contract Plans 02/03 depend on
- `.claude/skills/llm-mutate/{scripts,fixtures,tmp}` directories exist for downstream file placement
- No blockers

---
*Phase: 04-llm-mutation-skill*
*Completed: 2026-05-26*

## Self-Check: PASSED

- run_mutant_spec.sh: FOUND
- SKILL.md: FOUND
- README.md: FOUND
- 04-01-SUMMARY.md: FOUND
- commit a1889d3: FOUND
- commit 307d776: FOUND
