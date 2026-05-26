# Roadmap: Mutation Testing Demo

## Overview

Six phases take this project from an empty repo to a recording-ready demo that proves 100% code coverage is a lie. The build order is dependency-constrained: licensing must be resolved before any code is written, the library must exist before tests, tests must exist before either mutation tool, and both tools must produce reports before the side-by-side comparison and narrative artifacts can be assembled. Phase 4 (the LLM skill) carries the highest implementation risk and requires deeper research at planning time. Phase 6 is a hard validation gate — the demo does not leave the repo until it runs cleanly end-to-end on the recording machine.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Repo Foundation** - Public repo, locked Gemfile, `.mutant.yml`, and clean `bundle install`
- [ ] **Phase 2: Library and Weak Tests** - Six date/time functions plus a 100%-covered RSpec suite with deliberate boundary omissions
- [ ] **Phase 3: mutant Baseline** - Traditional mutation run producing a kill-rate report with equivalence audit
- [ ] **Phase 4: LLM Mutation Skill** - Full `/llm-mutate` Claude Code skill with generate/replay modes and cost reporting
- [ ] **Phase 5: Comparison and Narrative** - Side-by-side comparison, demo branch states, README, shot list, and narration script
- [ ] **Phase 6: End-to-End Validation** - Full two-act demo verified clean on the recording machine

## Phase Details

### Phase 1: Repo Foundation
**Goal**: The repo is publicly visible on GitHub, correctly licensed for `mutant --usage opensource`, and `bundle install` runs clean from a fresh clone — every subsequent phase can start without a licensing or dependency surprise.
**Depends on**: Nothing (first phase)
**Requirements**: REPO-01, REPO-02, REPO-03, REPO-04, REPO-05
**Success Criteria** (what must be TRUE):
  1. `git clone` followed by `bundle install` completes without errors on a clean machine
  2. Repo is public on GitHub and carries an OSS license file
  3. `.mutant.yml` contains `usage: opensource` and `bundle exec mutant run` does not throw a licensing error
  4. `.ruby-version` pins a Ruby 3.4.x release and the README quickstart is present
**Plans**: 4 plans
  - [x] 01-01-PLAN.md — Wave 0: human-verify Ruby 3.4.x is installed locally (precondition gate)
  - [x] 01-02-PLAN.md — Wave 1: write the seven Phase 1 source files (LICENSE, README.md, Gemfile, .ruby-version, .mutant.yml, .gitignore, .github/workflows/ci.yml)
  - [ ] 01-03-PLAN.md — Wave 2: run `bundle install` to generate Gemfile.lock and create initial git commit on `main`
  - [ ] 01-04-PLAN.md — Wave 3: create public GitHub repo at `actowery/coverage-is-a-lie`, push, and verify first CI run is green

### Phase 2: Library and Weak Tests
**Goal**: All six `DateUtils` functions exist with non-trivial branching logic and the RSpec suite achieves 100% line and branch coverage while deliberately omitting boundary cases — the "green but broken" premise of the demo is proven and blind-review confirmed.
**Depends on**: Phase 1
**Requirements**: LIB-01, LIB-02, LIB-03, LIB-04, LIB-05, LIB-06, LIB-07, TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06
**Success Criteria** (what must be TRUE):
  1. `bundle exec rspec` passes green and SimpleCov reports 100% line and branch coverage on the library
  2. Suite passes identically under `TZ=UTC` and `TZ=America/New_York`
  3. A reviewer who did not build the library agrees the test suite looks like plausible first-pass coverage (no obvious straw-man tells)
  4. Every function contains at least one boundary condition (leap-day, negative duration, off-by-one, weekend boundary) that the suite omits
**Plans**: TBD

### Phase 3: mutant Baseline
**Goal**: `bundle exec mutant run` executes against all six library functions, produces a `tmp/mutant-report.txt` with kill rate and alive-mutation diffs, and a manual equivalence audit labels the meaningful survivors — Act 1 of the demo has its evidence.
**Depends on**: Phase 2
**Requirements**: MUT-01, MUT-02, MUT-03, MUT-04, MUT-05
**Success Criteria** (what must be TRUE):
  1. `bundle exec mutant run` completes against all six functions without hanging (timeout guard active)
  2. `tmp/mutant-report.txt` exists, contains kill rate and at least one alive-mutation diff
  3. SimpleCov does not load during mutant runs (env-guarded)
  4. Manual equivalence audit is complete — each surviving mutant is labeled as equivalent or meaningful
**Plans**: TBD

### Phase 4: LLM Mutation Skill
**Goal**: `/llm-mutate --generate` calls the Anthropic API and produces semantically meaningful mutations with plain-English descriptions; `/llm-mutate --replay` reads a committed fixture and reproduces the canonical demo output identically on any machine — the skill is demo-safe and cost-bounded.
**Depends on**: Phase 3
**Requirements**: SKILL-01, SKILL-02, SKILL-03, SKILL-04, SKILL-05, SKILL-06, SKILL-07, SKILL-08, SKILL-09, SKILL-10, SKILL-11
**Success Criteria** (what must be TRUE):
  1. `/llm-mutate --replay` produces identical `tmp/llm-mutation-report.md` output across three consecutive runs
  2. `/llm-mutate --generate` calls the Anthropic API, respects the `MAX_MUTATIONS` cap, and logs token usage and estimated cost
  3. The report includes at least one mutation with a plain-English description, a diff, and a kill/survive verdict for each of the six library functions
  4. Non-compilable mutation candidates are rejected via `ruby -c` and their count is logged; they do not appear as survivors
  5. The skill is invokable as `/llm-mutate` inside a Claude Code session without any manual file editing
**Plans**: TBD
**Research note**: Plan this phase with `/gsd-plan-phase --research-phase 4` — prompt architecture, fixture format, and RSpec exit-convention wiring are the high-risk areas requiring deeper research before implementation begins.

### Phase 5: Comparison and Narrative
**Goal**: `docs/comparison.md` maps mutations from both tools to the same six functions; `demo/weak-tests` and `demo/fixed-tests` branches exist with committed report artifacts; the README, shot list, and narration script give a presenter everything needed to record the demo without improvising.
**Depends on**: Phase 4
**Requirements**: COMP-01, COMP-02, DEMO-01, DEMO-02, DEMO-03, DOC-01, DOC-02, DOC-03, DOC-04
**Success Criteria** (what must be TRUE):
  1. `docs/comparison.md` contains a table covering all six functions with kill/survive verdicts from both tools, and calls out at least three mutations where the two tools diverge with one-sentence explanations
  2. `git checkout demo/weak-tests` and `git checkout demo/fixed-tests` each land in a self-consistent state with committed report artifacts; no manual file edits required
  3. README contains clearly-labeled Act 1 / Act 2 sections with the "100% coverage is a lie" and AI-era framing
  4. `docs/shot-list.md` enumerates every demo beat with terminal commands, expected output, and dual-audience cues
  5. `docs/narration-script.md` provides recording-ready voice-over text aligned to the shot list
**UI hint**: yes

### Phase 6: End-to-End Validation
**Goal**: The full two-act demo runs without errors on the recording machine; every command in the shot list is copy-pasteable and produces the documented output; the repo is ready to hand to a presenter.
**Depends on**: Phase 5
**Requirements**: VAL-01, VAL-02, VAL-03
**Success Criteria** (what must be TRUE):
  1. The complete two-act demo runs end-to-end on the recording machine within 24-48 hours of recording without any errors or permission prompts
  2. Every command in `docs/shot-list.md` is copy-pasted verbatim and produces the exact output documented
  3. `/llm-mutate --replay` run three consecutive times produces byte-identical `tmp/llm-mutation-report.md` output
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Repo Foundation | 2/4 | In Progress|  |
| 2. Library and Weak Tests | 0/TBD | Not started | - |
| 3. mutant Baseline | 0/TBD | Not started | - |
| 4. LLM Mutation Skill | 0/TBD | Not started | - |
| 5. Comparison and Narrative | 0/TBD | Not started | - |
| 6. End-to-End Validation | 0/TBD | Not started | - |
