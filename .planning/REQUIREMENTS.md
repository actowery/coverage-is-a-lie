# Requirements: Mutation Testing Demo

**Defined:** 2026-05-26
**Core Value:** A viewer watches the demo and immediately understands that coverage metrics can be gamed and that mutation testing — especially LLM-driven — is the missing assurance layer in an AI-assisted development era.

## v1 Requirements

### Repo Foundation

- [ ] **REPO-01**: Repo is public on GitHub with an OSS license file present, so `mutant` can run under `--usage opensource`
- [ ] **REPO-02**: `.ruby-version` pinned to a stable Ruby 3.4.x release
- [ ] **REPO-03**: Gemfile declares locked versions for rspec, simplecov, mutant, and mutant-rspec; `bundle install` runs clean (no `anthropic` SDK — the LLM skill runs inside Claude Code, not as Ruby code)
- [ ] **REPO-04**: `.mutant.yml` contains explicit `usage: opensource` key
- [ ] **REPO-05**: README quickstart shows clone → bundle install → run-the-demo flow

### Date/Time Library (`DateUtils`)

- [ ] **LIB-01**: `DateUtils.days_between(start_date, end_date)` — integer days, supports reversed dates
- [ ] **LIB-02**: `DateUtils.add_business_days(date, n)` — skip weekends, supports negative `n`
- [ ] **LIB-03**: `DateUtils.leap_year?(year)` — full three-clause Gregorian rule (divisible by 4, not 100, except 400)
- [ ] **LIB-04**: `DateUtils.age_in_years(birthdate, as_of:)` — handles leap-day birthdays, birthday-this-year off-by-one
- [ ] **LIB-05**: `DateUtils.next_occurrence_of_weekday(from_date, weekday)` — clearly-documented return-same-day-or-next-week semantics
- [ ] **LIB-06**: `DateUtils.weeks_between(start_date, end_date)` — integer division, supports reversed dates
- [ ] **LIB-07**: Library is dependency-free pure Ruby; no DST / timezone behavior in surface

### Weak Test Suite

- [ ] **TEST-01**: RSpec suite covers every function; suite passes green
- [ ] **TEST-02**: SimpleCov configured with line + branch coverage, `minimum_coverage 100`, loaded as the very first line of `spec_helper`, guarded behind `ENV['COVERAGE']`
- [ ] **TEST-03**: Coverage report shows 100% line + branch on the library
- [ ] **TEST-04**: Tests use real assertions (`expect(x).to eq(y)`) — failure mode is omission of boundary cases, not absence of assertions
- [ ] **TEST-05**: Suite passes identically under `TZ=UTC` and `TZ=America/New_York`
- [ ] **TEST-06**: Blind review by a second pair of eyes confirms the weak tests look like plausible first-pass coverage (no obvious straw-man tells)

### Mutant Gem Baseline (Act 1 reveal — traditional)

- [ ] **MUT-01**: `bundle exec mutant run` executes against all six library functions
- [ ] **MUT-02**: Run produces `tmp/mutant-report.txt` capturing kill rate and alive-mutation diffs
- [ ] **MUT-03**: `spec_helper` includes a `Timeout.timeout(5)` guard so infinite-loop mutations don't hang the suite
- [ ] **MUT-04**: SimpleCov does not load during mutant runs (env-guarded)
- [ ] **MUT-05**: Manual equivalence audit performed on top survivors; equivalent mutants labeled in report notes

### LLM Mutation Skill (`/llm-mutate`)

- [ ] **SKILL-01**: Skill lives at `.claude/skills/llm-mutate/SKILL.md` with valid frontmatter; invokable as `/llm-mutate`
- [ ] **SKILL-02**: Skill supports two modes via arg: `/llm-mutate --generate` (Claude generates mutations live in the current session) and `/llm-mutate --replay` (reads committed fixture). The demo uses `--replay`.
- [ ] **SKILL-03**: Skill is pure SKILL.md instructions — no external API client, no API key. Claude Code is the LLM runtime; the skill instructs Claude to generate mutations using its Read/Write/Bash tools in the session. Model is whatever the session is configured to use (Sonnet 4.6 recommended).
- [ ] **SKILL-04**: Mutations are semantically meaningful per Meta's ACH approach — generated as "what a careless developer would write" descriptions, not exhaustive operator substitutions
- [ ] **SKILL-05**: Pipeline validates each mutation with `ruby -c` and discards non-compilable candidates with a logged count
- [ ] **SKILL-06**: Generate mode enforces a `MAX_MUTATIONS` cap (default 20) to bound session token usage
- [ ] **SKILL-07**: For each surviving mutation candidate, the skill writes the mutated file to `tmp/mutants/<id>.rb`, runs the RSpec wrapper, and classifies killed (exit 0) vs survived (exit 1)
- [ ] **SKILL-08**: Output report `tmp/llm-mutation-report.md` includes plain-English mutation description, diff, kill/survive verdict, and an aggregate mutation score
- [ ] **SKILL-09**: Report includes an estimated-cost footer derived from approximate token counts (input/output bytes × Sonnet 4.6 rates) — labeled "estimated" since live token metering is not available from inside a skill
- [ ] **SKILL-10**: A committed fixture file lets `--replay` reproduce the canonical demo output identically across machines
- [ ] **SKILL-11**: Skill includes a thin `scripts/run_mutant_spec.sh` wrapper that exits 0 if RSpec passes (mutation killed) and 1 if it fails (mutation survived)

### Side-by-Side Comparison (Act 2 reveal — LLM)

- [ ] **COMP-01**: `docs/comparison.md` presents a table mapping mutations from each tool to the same six functions, with kill/survive verdicts
- [ ] **COMP-02**: Comparison highlights at least three mutations the LLM caught that mutant missed (or vice versa) with one-sentence explanations of why each matters

### Demo States

- [ ] **DEMO-01**: `demo/weak-tests` git branch holds the green-but-broken state with committed `tmp/mutant-report.txt` and `tmp/llm-mutation-report.md`
- [ ] **DEMO-02**: `demo/fixed-tests` git branch holds the improved test suite that kills all previously-surviving mutations, with refreshed report artifacts committed
- [ ] **DEMO-03**: Switching between the two branches requires only `git checkout` — no manual file edits

### Narrative Artifacts

- [ ] **DOC-01**: README has clearly-labeled Act 1 / Act 2 narrative sections with the "100% coverage is a lie" framing and AI-era angle
- [ ] **DOC-02**: `docs/shot-list.md` enumerates each beat of the recording with terminal commands, expected on-screen output, and dual-audience cues (engineer-deep vs leadership-narrative)
- [ ] **DOC-03**: `docs/narration-script.md` provides recording-ready voice-over text aligned to the shot list
- [ ] **DOC-04**: README documents the Claude Code `~/.claude/settings.json` permissions needed on the demo machine to avoid mid-recording permission prompts

### Demo Validation

- [ ] **VAL-01**: Full two-act demo runs end-to-end on the recording machine within 24-48 hours of recording without errors
- [ ] **VAL-02**: All commands in `docs/shot-list.md` are copy-pasteable and produce the documented output
- [ ] **VAL-03**: Skill's `--replay` mode produces identical output across at least three consecutive runs

## v2 Requirements

Deferred. Tracked but not in current roadmap.

### Skill Enhancements

- **SKILL-V2-01**: Coverage-gap-targeted mutation selection using SimpleCov branch data
- **SKILL-V2-02**: Configurable `--mutations-per-function` CLI flag
- **SKILL-V2-03**: Optional LLM-driven equivalence-check step (post-mutation) to flag semantically equivalent mutants
- **SKILL-V2-04**: CI integration example (GitHub Actions workflow) running mutation testing on PRs

### Demo Polish

- **DOC-V2-01**: Polished public-facing blog post version of the README
- **DOC-V2-02**: Slide deck with talking points for live workshop delivery

## Out of Scope

| Feature | Reason |
|---------|--------|
| Recording / producing the actual demo video | Human deliverable; project produces the recording-ready repo and script |
| Languages other than Ruby | Single-language keeps demo tight and matches PE audience ecosystem |
| Hosting the LLM mutator as a managed service or web UI | Skill is invoked locally inside Claude Code; no UI |
| Replacing or wrapping `mutant` | We run mutant as-is; LLM-driven mutator is the novelty, not a mutant fork |
| DST / timezone-sensitive library functions | Environment-fragile; distracts from the thesis without adding narrative value |
| Auto-fix suggestions from LLM skill | Human writing the fix is the pedagogical moment; auto-fix muddies the story |
| Mutation testing of anything beyond the demo library | Skill should be reusable, but proving it on multiple codebases is a follow-up |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 1 | Pending |
| REPO-02 | Phase 1 | Pending |
| REPO-03 | Phase 1 | Pending |
| REPO-04 | Phase 1 | Pending |
| REPO-05 | Phase 1 | Pending |
| LIB-01 | Phase 2 | Pending |
| LIB-02 | Phase 2 | Pending |
| LIB-03 | Phase 2 | Pending |
| LIB-04 | Phase 2 | Pending |
| LIB-05 | Phase 2 | Pending |
| LIB-06 | Phase 2 | Pending |
| LIB-07 | Phase 2 | Pending |
| TEST-01 | Phase 2 | Pending |
| TEST-02 | Phase 2 | Pending |
| TEST-03 | Phase 2 | Pending |
| TEST-04 | Phase 2 | Pending |
| TEST-05 | Phase 2 | Pending |
| TEST-06 | Phase 2 | Pending |
| MUT-01 | Phase 3 | Pending |
| MUT-02 | Phase 3 | Pending |
| MUT-03 | Phase 3 | Pending |
| MUT-04 | Phase 3 | Pending |
| MUT-05 | Phase 3 | Pending |
| SKILL-01 | Phase 4 | Pending |
| SKILL-02 | Phase 4 | Pending |
| SKILL-03 | Phase 4 | Pending |
| SKILL-04 | Phase 4 | Pending |
| SKILL-05 | Phase 4 | Pending |
| SKILL-06 | Phase 4 | Pending |
| SKILL-07 | Phase 4 | Pending |
| SKILL-08 | Phase 4 | Pending |
| SKILL-09 | Phase 4 | Pending |
| SKILL-10 | Phase 4 | Pending |
| SKILL-11 | Phase 4 | Pending |
| COMP-01 | Phase 5 | Pending |
| COMP-02 | Phase 5 | Pending |
| DEMO-01 | Phase 5 | Pending |
| DEMO-02 | Phase 5 | Pending |
| DEMO-03 | Phase 5 | Pending |
| DOC-01 | Phase 5 | Pending |
| DOC-02 | Phase 5 | Pending |
| DOC-03 | Phase 5 | Pending |
| DOC-04 | Phase 5 | Pending |
| VAL-01 | Phase 6 | Pending |
| VAL-02 | Phase 6 | Pending |
| VAL-03 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 45 total
- Mapped to phases: 45
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-26*
*Last updated: 2026-05-26 after roadmap creation*
