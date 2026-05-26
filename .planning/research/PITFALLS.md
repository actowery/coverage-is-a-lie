# Pitfalls Research

**Domain:** Ruby mutation testing demo with LLM-driven mutations (mutant gem + Claude Code skill)
**Researched:** 2026-05-26
**Confidence:** HIGH (licensing verified from official docs; LLM mutation pitfalls verified from Meta's published research; Ruby timezone issues verified from community sources; Claude Code skill issues verified from open issue tracker)

---

## Critical Pitfalls

### Pitfall 1: mutant Licensing Trap — Demo Repo Must Be Public or You Need a Commercial Subscription

**What goes wrong:**
The mutant gem has two usage modes: `--usage opensource` (free, public repos only) and `--usage commercial` (paid subscription, $30/month or $250/year per developer). If the demo repo is private — even temporarily, even internally — using `--usage opensource` violates the license terms. The gem enforces this via the `mutant-license` gem, which contacts a license server at `bundle install` time with a license key. Running without a valid usage flag causes the tool to refuse execution, which is a demo-killing failure.

**Why it happens:**
Developers assume "it's just a demo / internal tool" falls under a gray area. It doesn't. The license is binary: public OSS repo or paid subscription. There's no trial tier. The `--usage opensource` flag exists in the config and is easy to cargo-cult from tutorials without reading the restriction.

**How to avoid:**
Make the decision at project initialization: either (a) keep the repo public from day one and use `--usage opensource`, or (b) purchase a commercial subscription before any private repo work. Commit the `.mutant.yml` config with the `usage:` key set explicitly. Document this decision in the README so anyone who clones the repo knows what's required.

**Warning signs:**
- mutant exits early with a license error mentioning Schirp DSO LTD
- CI runs fail with license-related output but pass locally (different license key environments)
- You copy a `.mutant.yml` config from a tutorial that omits the `usage:` field

**Phase to address:**
Phase 1 (project setup / repo initialization) — decide public vs private before writing any code.

---

### Pitfall 2: Equivalent Mutants Masquerade as Survivors and Inflate the "Weakness" Narrative

**What goes wrong:**
An equivalent mutant is a syntactically different but semantically identical version of the code — no test can ever kill it because it behaves the same way. These appear as "surviving mutants" in both the mutant gem output and in LLM-generated mutation results. If the demo shows a high survivor count and a significant fraction are equivalent, the claim "your tests are weak" is partially false — those tests aren't weak, the mutations are unfair. An informed audience (senior engineers, anyone who has done mutation testing before) will call this out and dismiss the entire narrative.

**Why it happens:**
Traditional mutation operators like arithmetic replacement (`+` → `-`) are notorious for producing equivalent mutants on certain expressions. LLMs make it worse: Meta's production system found ~25% of LLM-generated mutants that built and passed were equivalent, and 61% of those were because the LLM inserted misleading comments describing bugs without changing any executable code.

**How to avoid:**
- For the mutant gem: scope the demo library to operations where classic operators produce non-equivalent mutations. Date/time logic with boundary checks (DST transitions, leap year boundaries, negative duration handling) is good for this because arithmetic mutations there change observable behavior. Avoid mutations on pure constant expressions where `x + 0` vs `x - 0` is equivalent.
- For LLM mutations: add a post-processing step that strips added comments and checks for syntactically identical mutations before reporting survivors. This is exactly what Meta did to improve their equivalence detector from 0.79 precision to 0.95 precision.
- Label "equivalent mutant (skipped)" in the output rather than hiding them, so the audience sees you've accounted for them.

**Warning signs:**
- The survived mutant report shows changes only to comments or whitespace
- A mutant survives on a pure arithmetic identity (`x * 1`, `x - 0`, `x + 0`)
- Multiple survivors show the same observable behavior as the original when you manually test them

**Phase to address:**
Phase 2 (library design) — design the utility functions to produce mostly non-equivalent mutations. Phase 3 (mutant integration) — add a manual equivalence audit step to the demo script so equivalent survivors are labeled before presenting results.

---

### Pitfall 3: LLM Non-Determinism Breaks Demo Reproducibility Between Runs

**What goes wrong:**
LLMs are non-deterministic. Even with `temperature: 0`, two runs of the same mutation prompt against the same code produce different mutations. This means the set of mutations changes between rehearsal and the live demo, the mutation score shifts unpredictably, and specific "interesting" mutations you planned to highlight may not appear. Research confirms: even fixed-seed inference shows variation due to GPU floating-point non-associativity in parallel operations. Newer model versions produce different output entirely.

**Why it happens:**
The Claude API does not guarantee identical outputs across requests at temperature 0. Model weights change between versions. Batch size and GPU scheduling affect floating-point summation order. The LLM skill is invoked fresh each time it runs.

**How to avoid:**
- Capture a golden set of mutations from a dry run and persist them in a fixture file (e.g., `spec/fixtures/llm_mutations.json`). The skill should have two modes: `generate` (calls the API, writes to fixtures) and `replay` (reads from fixtures, runs tests). The demo always uses `replay` mode for predictable output.
- Pin the model version explicitly in the skill (not `claude-sonnet-latest` but the exact model ID string) so a model upgrade during project work doesn't shift results silently.
- Run the full demo end-to-end at least once 24-48 hours before the recording to catch any drift.

**Warning signs:**
- Dry runs show different surviving mutations each time
- A mutation you planned to narrate isn't generated
- Kill rates shift by more than 5% between consecutive runs
- The model version string in the skill uses an alias rather than a pinned ID

**Phase to address:**
Phase 4 (LLM skill development) — build the generate/replay duality from the start, not as an afterthought.

---

### Pitfall 4: LLM Generates Non-Compilable or Syntactically Invalid Mutants, Wasting Budget and Confusing Output

**What goes wrong:**
LLMs generate Ruby code that does not parse or raises a `SyntaxError` when loaded. The mutation is neither killed nor survived — it errors. Meta's production system found that only 29% of generated mutants built successfully (9,095 of 31,677 total). For Ruby, common failure modes: undefined local variables the LLM invented, method calls on wrong receiver types, missing `end` keywords, and mutation of string interpolation that breaks syntax. In a demo context, a stack of syntax error mutants drowns the interesting results in noise and suggests the tool is broken.

**Why it happens:**
LLMs are trained to produce plausible-looking code, not verified-parseable code. Mutations that change method signatures or control flow boundaries are especially prone to structural destruction. The LLM doesn't run the code — it predicts tokens.

**How to avoid:**
- The skill must include a syntax validation step after generating each mutation: run `ruby -c <tempfile>` and discard any mutant that fails. Log the rejection reason.
- Add a semantic smoke-check: `require` the mutated file in a subprocess with no test load and check for `LoadError`. Discard if it fails.
- Report compile-error rejections separately in the output (`N mutations generated, M invalid (syntax), K survived, J killed`) — this shows the audience the LLM has quality variance, which is actually an honest and interesting data point.
- Constrain the mutation prompt to single-expression changes ("mutate only line X") rather than whole-function rewrites, which dramatically reduces structural destruction errors.

**Warning signs:**
- More than 20% of LLM-generated mutations error rather than pass/fail
- Output contains `SyntaxError`, `NameError: undefined local variable`, or `LoadError`
- The mutation diff spans more than 3-5 lines

**Phase to address:**
Phase 4 (LLM skill development) — build validation into the mutation pipeline, not the reporting layer.

---

### Pitfall 5: LLM Cost Runaway on Iterative Demo Development

**What goes wrong:**
Each mutation generation call consumes tokens for the source file, the mutation prompt, and the response. During development, a developer iterates on the prompt 20-30 times against the same codebase. If the skill also calls the API to verify each mutation (equivalence detection, test running feedback), costs compound. Claude Sonnet 4.6 at production pricing: a 500-token source file + 200-token prompt + 300-token response = ~1,000 tokens per mutation. At 50 mutations per run and 30 prompt iterations, that's 1.5M tokens in development alone before any optimization.

**Why it happens:**
Prompt engineering is inherently iterative. Developers don't track API costs during development. Skills don't have built-in budget caps. The generation/validation loop expands scope quietly.

**How to avoid:**
- Hardcode a `MAX_MUTATIONS` constant in the skill (default: 20 for development, configurable to 50 for demo). Never generate unbounded mutations.
- During prompt development, use a single function from the library (not the whole file) as the target — reduces input tokens by 60-70%.
- Use the fixture replay mode (Pitfall 3) during prompt iteration so you only call the API when testing new prompt strategies, not when testing the demo flow itself.
- Add a dry-run flag that prints the prompt and estimated token count without calling the API.

**Warning signs:**
- No `MAX_MUTATIONS` guard in the skill
- Development uses the whole library file as context for every iteration
- No distinction between "generate new mutations" and "replay cached mutations" in the skill invocation

**Phase to address:**
Phase 4 (LLM skill development) — establish budget guardrails in the skill before iterative prompt development begins.

---

### Pitfall 6: Weak Tests That Look Obviously Fake Undermine the Narrative

**What goes wrong:**
The demo's power depends on the audience believing the weak tests could plausibly have been written by a real (or AI-assisted) engineer. If the tests clearly assert nothing — `expect(result).not_to be_nil`, single happy-path examples with no boundary cases, or tests that simply call the function without asserting the return value — a technically savvy audience dismisses the demo immediately: "Nobody actually writes tests like that. This is a straw man." The narrative collapses.

**Why it happens:**
It's tempting to make the weakness obvious to ensure the demo "works." But the optimal weak test for demo purposes is one that looks like reasonable first-pass coverage: it hits every line (passes SimpleCov at 100%), it has real assertions that verify correct behavior on normal inputs, but it completely omits boundary conditions, edge cases, and error paths. The weakness is in what's missing, not in what's present.

**How to avoid:**
- Write tests that a competent engineer in a hurry would write: correct on the happy path, reasonable descriptions, real matchers. The only failure is omission of edge cases.
- Use `expect(result).to eq(expected_value)` not `expect(result).not_to be_nil`.
- Include at least one test per method that asserts a real value on a normal input — make it pass. Then simply omit the test for the DST edge case, the leap year boundary, the negative duration, etc.
- Review the weak tests with the "would a senior engineer on PR review flag anything?" test. If the answer is "yes, obviously," the tests are too weak. The reveal should be surprising.

**Warning signs:**
- Tests use `not_to be_nil` as their primary assertion
- Test descriptions use vague language: "it works", "it does something"
- Tests call the function but don't assert the return value at all
- Coverage passes because the test file loads the class, not because it exercises the branches

**Phase to address:**
Phase 2 (demo library + test suite design) — design weakness by omission, not by obviousness.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip mutation fixture system; call API live each demo run | Simpler skill implementation | Non-reproducible demos; cost burn on every rehearsal | Never — fixtures are load-bearing for demo reliability |
| Use `--usage opensource` on a private repo | No subscription cost | License violation; tool refuses to run if repo is ever private | Never — decide public vs private at setup |
| Single LLM prompt for all mutations in one call | Fewer API calls | LLM generates whole-function rewrites that destroy structure; higher syntax error rate | Never for production skill; acceptable for early spike |
| Rely on mutant's default concurrency | Zero configuration | Runtime explosion on any suite larger than trivial; hangs in demo | Acceptable only if library is truly tiny (< 10 tests) |
| Hardcode the current model alias (`claude-sonnet-latest`) | Always uses latest model | Silent result drift when model updates | Never in demo-facing skill; pin exact model ID |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| mutant + RSpec | Running `mutant run` without `--include lib` and `--require` flags causes unresolved subject errors | Always specify `--include lib --require <subject_file>` or configure in `.mutant.yml` |
| mutant + SimpleCov | Loading SimpleCov in spec_helper during mutant runs causes false coverage reports and slows mutation testing | Guard SimpleCov behind `ENV.fetch('COVERAGE', nil)` so it only loads during coverage runs |
| timecop + mutant | Timecop.freeze in a shared example group persists across forked mutation processes in some Ruby versions, causing test pollution | Use `Timecop.freeze` with a block (not the class-level freeze) and always pair with `Timecop.return` in an `ensure` |
| LLM skill + Bash permissions | The `allowed-tools` frontmatter in a SKILL.md does not currently propagate to Bash command permissions at execution time (open issue #14956) | Add the required Bash patterns to `~/.claude/settings.json` globally before demo; document this as a setup step |
| Claude Code skill + non-interactive invocation | Skills/slash-commands only work in interactive Claude Code sessions; `claude -p` (non-interactive) does not recognize slash command syntax | The demo must be run from an interactive Claude Code session; document this constraint; test this exact invocation path before recording |
| Ruby `Time.now` in CI | CI servers typically run in UTC; local machines run in the developer's system timezone; date arithmetic using `Time.now` without `.utc` produces different results in each environment | Always use `Time.now.utc` or `Time.now.getutc` for arithmetic in the utility library; freeze time in tests with a fixed UTC timestamp |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| mutant runs full test suite per mutation without timeout | Demo hangs indefinitely on any mutation that creates an infinite loop (common with arithmetic operator mutations on loop bounds) | Add `config.around(:each) { |ex| Timeout.timeout(5, &ex) }` to `spec_helper.rb` | Immediately on first infinite-loop mutation |
| LLM skill generates mutations sequentially with synchronous API calls | Demo takes 3-5 minutes to produce results; audience loses interest | Batch mutation generation into a single API call requesting N mutations at once; or pre-generate and replay from fixtures | Any demo context where generation happens live |
| mutant concurrency set too high for the demo machine | Random test failures during mutation runs due to resource contention | Set `concurrency: 2` in `.mutant.yml` for demo; test on the actual recording machine | Depends on machine; fails unpredictably |
| Loading the full app environment for each mutation fork | Slow mutation startup time multiplied by mutation count | Keep the demo library dependency-free (no Rails, no ActiveRecord); pure Ruby only | Any mutation suite with Rails or large gem dependency chain |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing raw mutant output during demo | Wall of text; audience loses the narrative thread | Pipe output through a summary formatter that shows only: total mutations, killed, survived, and a table of survivors with the changed line |
| Showing LLM-generated mutations before they are filtered | Syntax errors and obvious-nonsense mutations reduce confidence in the approach | Filter in the skill before displaying; show final valid-mutation count only |
| Running `mutant` and the LLM skill back-to-back without a pause | Audience cannot see the comparison; both produce similar-looking output | Separate the two runs visually; use a clear header/banner in the terminal output; consider a side-by-side diff table in the README |
| The "fixed tests" state is in a separate branch the presenter forgets to switch to | Narrative arc breaks; presenter fumbles with git during recording | Set up `git worktree` for the fixed state OR use a single-repo approach with a `bin/demo-phase` script that patches and unpatches tests deterministically |

---

## "Looks Done But Isn't" Checklist

- [ ] **mutant license**: Verify `usage:` key is set in `.mutant.yml` AND the repo's access level (public/private) matches the chosen mode — verify with `mutant run --help` and inspect config output
- [ ] **LLM mutation fixtures**: Confirm the skill has a `replay` mode AND that the fixture file is committed to the repo — verify by running the skill with `--replay` flag on a fresh clone
- [ ] **Timeout guard**: Confirm `Timeout.timeout` is present in `spec_helper.rb` before running any mutant job — verify by intentionally adding `loop { }` to a method and confirming mutant kills it within the timeout
- [ ] **Timezone consistency**: Confirm all `Time.now` calls in the demo library use `.utc` — run the full test suite with `TZ=UTC` and `TZ=America/New_York` and confirm identical results
- [ ] **Weak tests look plausible**: Have one person not involved in building the demo review the weak test suite blind — verify they say "this looks like normal first-pass test coverage"
- [ ] **Claude Code skill permissions**: Confirm the demo machine's `~/.claude/settings.json` has all required Bash patterns in the allow list — verify by running the skill start-to-finish in a fresh terminal before recording
- [ ] **Model version pinned**: Confirm the skill uses a pinned model ID string, not an alias — grep the skill file for `claude-sonnet` and verify it matches a specific versioned ID
- [ ] **End-to-end dry run**: Run the full two-act demo (weak tests → mutant baseline → LLM mutations → fixed tests → mutant rerun) start-to-finish 24 hours before recording on the recording machine

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| License violation discovered mid-project (repo is private, using opensource flag) | MEDIUM | Make repo public immediately; OR purchase a monthly subscription; update `.mutant.yml` `usage:` key; re-run to verify |
| LLM fixture missing; demo requires live API calls | LOW | Run `skill generate` once with budget cap set; commit the generated fixture file; switch to `replay` mode |
| Demo reveals high equivalent-mutant rate publicly | MEDIUM | Audit survivors manually; label equivalents in the output; add a "known equivalent" exclusion list to the demo script; reframe: "X of Y survivors are equivalent — mutation testing tools all have this, here's how to filter them" |
| Syntax error rate on LLM mutations is high during live demo | LOW | Switch to replay mode (fixture generated with pre-filtered mutations); or add live filtering and report the rejection count as an honest data point |
| CI timezone mismatch causes flaky test in demo suite | LOW | Add `TZ=UTC` prefix to all test runner commands in the Makefile/bin scripts; add a note to README |
| Claude Code permission prompt interrupts demo flow | LOW | Pre-configure `~/.claude/settings.json` with required allow rules; test in a fresh terminal before recording; have a "setup" section in the README that runs a permission-seeding script |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| mutant license violation | Phase 1: Repo setup | Run `mutant run` against a single method; confirm no license error |
| Equivalent mutants inflate survivor count | Phase 2: Library design + Phase 3: mutant integration | Manually audit top 10 survivors; confirm < 20% are equivalent |
| LLM non-determinism breaks reproducibility | Phase 4: Skill development | Run skill twice; confirm identical mutation set via fixture replay |
| LLM generates non-compilable mutants | Phase 4: Skill development | Check skill output for syntax errors; confirm `ruby -c` validation step present |
| LLM cost runaway | Phase 4: Skill development | Confirm `MAX_MUTATIONS` cap present; run `--dry-run` flag; review API usage dashboard |
| Weak tests look like a straw man | Phase 2: Test suite design | Blind review by a colleague unfamiliar with the demo |
| Flaky tests confound kill/survive verdicts | Phase 2: Test suite design | Run full RSpec suite 5 times; confirm zero intermittent failures |
| Timeout absent; infinite-loop mutation hangs | Phase 3: mutant integration | Inject a `loop {}` method; verify mutant kills it within timeout |
| Timezone inconsistency in CI vs local | Phase 2: Library + test design | Run `TZ=UTC bundle exec rspec` and `TZ=America/New_York bundle exec rspec`; both must pass |
| `timecop` + mutant fork interaction | Phase 2: Test design | Use block-form `Timecop.freeze`; run mutation suite; confirm no frozen-time leakage across mutations |
| Claude Code skill permissions break demo flow | Phase 4: Skill development + Phase 5: Demo assembly | Run skill in fresh terminal on demo machine; confirm zero permission prompts |
| Demo narrative arc breaks (wrong git state) | Phase 5: Demo assembly | Run the two-act script from a fresh clone; verify state transitions are scripted |

---

## Sources

- mutant gem commercial licensing: https://github.com/mbj/mutant/blob/main/docs/commercial.md
- mutant gem `--usage opensource` enforcement mechanism: https://github.com/mbj/mutant/issues/964
- mutant gem timeout/infinite loop: https://www.rubydoc.info/gems/mutant/0.8.17 (README)
- Equivalent mutant problem (empirical evaluation): https://arxiv.org/html/2404.09241v1
- Equivalent mutant rates in LLM-generated mutations: https://arxiv.org/html/2501.12862v1 (Meta ACH paper)
- Meta "Mutation-Guided LLM-based Test Generation": https://arxiv.org/abs/2501.12862
- LLM mutation non-compilability rates (GPT-3.5: 38.3% non-compilable): https://arxiv.org/html/2406.09843v3
- LLM non-determinism root causes: https://www.flowhunt.io/blog/defeating-non-determinism-in-llms/
- Flaky tests and mutation testing score inflation: https://mir.cs.illinois.edu/marinov/publications/ShiETAL19FlakyMutation.pdf
- Ruby DateTime#=== ignores time component (uses Date#===): https://medium.com/@dvandersluis/an-rspec-time-issue-and-its-not-about-timezones-a89bbd167b86
- Ruby DST flaky tests: https://stevenharman.net/on-flaky-tests-time-precision-and-order-dependence
- timecop gem gotchas (freeze breaks benchmarks; Rails vs Ruby date mixing): https://github.com/travisjeffery/timecop
- Claude Code allowed-tools skill bug (issue #14956): https://github.com/anthropics/claude-code/issues/14956
- Claude Code skill invocation interactive-only constraint: https://code.claude.com/docs/en/agent-sdk/slash-commands
- Claude Code permission configuration: https://code.claude.com/docs/en/permissions
- LLM agent cost runaway prevention: https://relayplane.com/blog/agent-runaway-costs-2026
- InfoQ coverage of Meta LLM mutation paper: https://www.infoq.com/news/2026/01/meta-llm-mutation-testing/

---
*Pitfalls research for: Ruby mutation testing demo (mutant gem + Claude Code LLM mutator skill)*
*Researched: 2026-05-26*
