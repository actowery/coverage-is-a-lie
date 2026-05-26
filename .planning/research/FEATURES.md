# Feature Research

**Domain:** Ruby mutation-testing demo — "100% coverage is a lie"
**Researched:** 2026-05-26
**Confidence:** HIGH (table stakes and architecture), MEDIUM (LLM skill feature surface — some design decisions are novel and unverified against shipped skills)

---

## Feature Landscape

### Surface 1: Date/Time Utility Library

The library is the demo's specimen. Its job is not to be a production date library — it is to be a small, readable, edge-case-rich body of logic where mutations land visibly and the narrative "why would anyone miss this?" is obvious to an audience watching a recording. Every function should fit on one screen and have at least two classes of mutations that a naive 100%-covered test suite will miss.

**Recommended functions (with mutation-richness rationale):**

| Function | Signature (Ruby) | Why mutation-rich | Key mutations that survive naive tests |
|----------|-----------------|-------------------|-----------------------------------------|
| `days_between(start_date, end_date)` | `Date, Date -> Integer` | Off-by-one on inclusive/exclusive boundary; sign flip for negative durations; absolute vs signed return | `end - start` vs `(end - start).abs`; `>=` vs `>`; returning wrong sign when end < start |
| `add_business_days(date, n)` | `Date, Integer -> Date` | Skips weekends; n=0 edge; negative n (subtract); landing on holiday if holiday list added later | Loop direction flip; `>=` vs `>` on weekday check; fence-post on weekend skip |
| `leap_year?(year)` | `Integer -> Boolean` | Three-clause rule (div-by-4, div-by-100, div-by-400) is famously mis-implemented; each clause is an independent mutation target | Dropping the `% 400 == 0` clause entirely; `&&` vs `||` between clauses; `==` vs `!=` |
| `age_in_years(birthdate, as_of: Date.today)` | `Date, Date -> Integer` | Birthday-on-leap-day bug; birthday-not-yet-this-year off-by-one; negative age for future birthdates | `>=` vs `>` on birthday-passed check; missing leap-day fallback (Feb 28 vs Feb 29); integer truncation vs rounding |
| `next_occurrence_of_weekday(from_date, weekday)` | `Date, Integer -> Date` | Returns `from_date` itself when it matches vs always-next; modular arithmetic wrap | Returning `from_date` when weekday matches; `% 7` boundary; `+1` vs `+0` offset |
| `weeks_between(start_date, end_date)` | `Date, Date -> Float/Integer` | Integer division truncation vs rounding; partial week handling; sign for reversed dates | `/ 7` integer truncation losing partial weeks; sign of result when reversed; `days_between` delegation bug |

**Notes on scope:** Six functions is right. Fewer than four leaves the LLM mutator without enough material to produce a varied demo; more than six dilutes focus during recording. DST is intentionally excluded from the function surface — DST behavior in Ruby depends on system timezone and Time vs Date classes, making it unreliable in a self-contained demo without Timecop or a fake clock. The narrative richness comes from leap years, business-day logic, and off-by-one boundary conditions, which are fully deterministic without clock mocking.

---

### Surface 2: Demo Features (What Makes the Presentation Land)

#### Table Stakes

Features the demo must have or the narrative breaks. Missing any of these means the demo cannot be played from `git clone` to finished recording.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| 100%-coverage RSpec suite that passes green | Core premise — audience must see the green bar before the reveal | LOW | SimpleCov configured; line coverage must hit 100.0%; deliberately weak assertions (no boundary checks, no negative durations, no leap-day birthdays) |
| `mutant` gem integration producing a survived-mutation report | Baseline tool — establishes "traditional mutation testing" for the side-by-side | MEDIUM | Requires `.mutant.yml` or inline config; commercial license or `--usage opensource` flag; outputs kill rate, alive mutations with diffs |
| Survived-mutation diff output (killed vs alive, per method) | Audience needs to see exactly what was missed — text diffs are the "proof" | LOW | `mutant` provides this natively in its terminal output (e.g., `- @age >= 18` / `+ @age > 18`) |
| Kill rate / mutation score displayed as a number | The quantitative punch line: "100% coverage, 38% mutation score" | LOW | `mutant` reports this; LLM skill must also emit a score |
| "Fixed tests" branch or commit showing all mutations killed | Act 2 close — demo needs a payoff where the audience sees 100% mutation score | MEDIUM | Separate git branch or tagged commit; requires adding boundary/edge-case assertions that kill each survived mutant |
| README with demo flow and shot list | Recording-ready artifact; demo cannot be narrated without a script anchor | MEDIUM | Narrative arc: green CI → mutation reveal → LLM mutations → fix → kill rate 100%; maps commands to talking points |
| `bundle install` → demo commands run cleanly | Credibility — a demo that breaks during recording is dead | LOW | Gemfile.lock committed; Ruby version pinned via `.ruby-version`; CI badge optional but useful |

#### Differentiators

Features that make THIS demo different from any other mutation testing tutorial. These are what the audience remembers.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| LLM-driven mutation skill (Claude Code, Sonnet 4.6) | The headline novelty — mirrors Meta's ACH research; shows LLMs generating semantically meaningful mutations that operator-based tools miss | HIGH | The core innovation; detailed in Surface 3 below |
| Side-by-side comparison: `mutant` output vs LLM-skill output on same functions | Audience sees exactly where LLM adds value over traditional tools — not just "LLMs are better" but "here's the specific mutation that mutant missed and Claude caught" | MEDIUM | Requires structuring output of both runs to be directly comparable; likely a formatted table or split terminal view in the README/script |
| Mutations that look like real engineering bugs, not random operator flips | Traditional tools flip `>=` to `>` — valid but toy-feeling. LLM mutations simulate "developer forgot leap-day fallback," "copy-pasted weekend check has wrong direction," "used integer division where float was needed" — these feel like bugs a real engineer would ship | HIGH (via LLM skill) | Dependent on prompt engineering in the skill; the mutation description should be a one-sentence "what a careless developer might do" statement |
| AI-era framing: "AI-generated tests can hit every line without verifying behavior" | Directly addresses the audience's lived anxiety about AI-assisted development — coverage was always weak, but now it's actively misleading | LOW (narrative only) | This framing goes in README and narration script; no code required; high impact for skip-level leadership |
| Narration script with dual-track commentary (engineering detail + leadership narrative) | Mixed audience (deep engineers + tech-apt leadership) means the same demo needs two levels of explanation simultaneously | MEDIUM | README sections tagged for audience; shot list includes "leadership beat" and "engineering detail" markers |
| Mutation descriptions in plain English alongside code diffs | LLM skill outputs "This mutation simulates a developer who forgot that February 29 must fall back to February 28 in non-leap years" alongside the actual diff — this is what makes the output compelling vs just showing a `+/-` diff | MEDIUM (prompt design) | Part of LLM skill output contract; mutant gem does not do this; this is a key differentiator |

#### Anti-Features

Things that seem like good additions but hurt the demo.

| Feature | Why Requested | Why It's Wrong for This Demo | What to Do Instead |
|---------|---------------|------------------------------|-------------------|
| Web UI or interactive dashboard for the mutation skill | Makes it feel more "real" | Scope bloat; adds auth, hosting, and maintenance surface that's irrelevant to the thesis; obscures the "Claude Code skill you can adopt today" message | Keep it a CLI skill invoked from the terminal — the terminal is the demo surface |
| DST-dependent date functions in the library | Makes the edge cases feel even more real | DST behavior is timezone- and OS-dependent; will break on CI in different regions; requires Timecop or fake clock, which adds demo complexity that distracts from mutation testing | Lean on leap year + business day logic instead — equally brutal for mutation testing, fully deterministic |
| Replacing or wrapping the `mutant` gem | "Why use two tools?" | The side-by-side is the entire narrative; replacing mutant removes the baseline that makes LLM-driven mutations look like an upgrade | Run mutant as-is and run the LLM skill separately; compare outputs |
| Mutation testing of anything beyond the demo library | Shows the skill is reusable | Dilutes the demo; creates noise in the output; the "skill is reusable" message can be stated in the README without proving it on a second codebase during the demo | Note reusability in README; leave multi-codebase proof as a follow-up |
| Auto-fix suggestions from the LLM skill | Feels like a natural extension — "Claude found the gap, Claude should fix it" | Changes the demo's thesis from "mutation testing finds gaps" to "AI patches your tests" — the audience needs to own the fix to internalize the lesson | Show the fix in a separate "fixed tests" branch written by hand; the act of writing the fix is the pedagogical moment |
| Equivalent-mutation detection / filtering | Advanced feature present in Meta's ACH system | Adds complexity without demo value; in a 4-6 function library, every generated mutation should be non-equivalent by construction if the functions are written carefully | Curate the library and prompts to avoid equivalent mutations rather than building a filter |
| Async / batch mode for the LLM skill | Research shows ~80% cost savings vs one-at-a-time | For a demo, synchronous one-at-a-time output with per-mutation feedback is the better narrative experience; watching mutations generate live is part of the show | Document batch mode as a "production use" note in the skill README; default to synchronous |
| A full mutation-testing framework (own operator set) | "We could replace mutant entirely" | Out of scope per PROJECT.md; reinventing the wheel derails the timeline and dilutes the AI-era message | Use `mutant` for traditional baseline; LLM skill is the novelty layer |

---

### Surface 3: LLM-Driven Mutation Skill Features

The skill is a Claude Code slash command. It reads source files, generates mutations using Claude Sonnet 4.6, applies each mutation to a temp copy of the file, runs RSpec, and reports kill/survive verdict with a plain-English description of what the mutation simulates.

Meta's ACH research (Engineering at Meta, Sept 2025; InfoQ, Jan 2026) showed the core value proposition: LLMs generate domain-specific, semantically realistic mutations rather than generic operator substitutions. ACH achieved 73% test acceptance rate, with 36% of generated tests deemed privacy-relevant. The approach filters equivalent mutants, generates targeted tests alongside mutations, and focuses on realistic fault patterns.

The arxiv paper "A Comprehensive Study on Large Language Models for Mutation Testing" (2406.09843) confirms: GPT-4o detects 93.4% of real bugs vs 74.4% for traditional tools — ~19% improvement — by generating diverse AST-node mutations including literals, binary operations, and method invocations that operator-based tools never produce. The tradeoff is compilability (75.6% for LLMs vs 98.3% for rule-based), which the skill must handle gracefully.

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Coverage-targeted mutation selection (generate mutations for uncovered behavior, not random lines) | Core of Meta's approach — the skill should know what's weakly tested and target those areas | MEDIUM | Skill reads SimpleCov JSON output to identify which branches/conditions are executed but not asserted on; mutations target those |
| Per-mutation RSpec runner integration | The skill must actually run the tests to determine kill/survive — not just generate mutations | MEDIUM | Skill applies mutation to a temp file, runs `rspec --format progress`, parses exit code; restore original file after; must handle syntax errors from bad LLM output gracefully |
| Kill / survive verdict per mutation with plain-English description | Core output contract — audience needs to understand what each mutation represents | LOW-MEDIUM | LLM generates both the mutation and a one-sentence "what careless developer would do this" description; output format: mutation diff + description + verdict |
| Mutation score summary at end of run | Quantitative output to compare against `mutant` score | LOW | `(killed / total) * 100`; displayed at end of skill run |
| Graceful handling of non-compilable / syntax-error mutations | LLMs generate uncompilable code ~25% of the time (per research) | MEDIUM | Detect syntax error from `ruby -c` or RSpec load error; mark as "invalid mutation, skipped"; do not count in score denominator |
| Source file restoration after each mutation | Demo cannot leave the codebase in a mutated state | LOW | Write original content back after each RSpec run regardless of outcome; use begin/ensure pattern |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Semantically meaningful mutation prompting ("what would a careless developer write?") | Mutations that feel like real engineering bugs, not random operator flips — this is the key differentiator over traditional tools | MEDIUM-HIGH | Prompt engineering: "Generate a plausible mutation that simulates a mistake a developer might realistically make in this function. Focus on off-by-one errors, wrong comparison operators, incorrect handling of edge cases like leap years or negative values. Return the mutated function and one sentence describing what went wrong." |
| Coverage-gap targeting using SimpleCov JSON | Directs LLM attention to the functions/branches least exercised — mirrors Meta's mutation-guided approach | MEDIUM | Parse `.coverage/coverage.json`; identify methods with low branch coverage; weight mutation generation toward those methods |
| Comparison output table: `mutant` mutations vs LLM mutations side-by-side | The demo's narrative anchor — shows where LLMs add value beyond traditional tools | MEDIUM | After both tools run, skill (or README script) formats a comparison: function name, mutation type, tool that found it, whether killed or survived |
| Cost reporting per run (tokens used, estimated dollar cost) | Makes the "production adoption" question concrete — "this run cost $0.04" is a powerful closing beat | LOW | Count input/output tokens from Anthropic API response; multiply by Sonnet 4.6 pricing; display at end of run |
| Batch size 1 (synchronous, one mutation at a time) with live output | Demo experience: audience watches mutations generate and verdicts appear in real time | LOW | Deliberate design choice over async batch; see anti-features above |
| Configurable number of mutations per function | Lets the demo runner control depth vs speed for recording | LOW | CLI flag `--mutations-per-function N`, default 3 |

#### Anti-Features

| Feature | Why Requested | Why It's Wrong for This Demo | What to Do Instead |
|---------|---------------|------------------------------|-------------------|
| Equivalent-mutation detection (LLM filters own output) | Meta's ACH includes an LLM-based equivalence detector (precision 0.79, recall 0.47) | Adds a second LLM call per mutation; doubles cost and latency; in a 4-6 function library the problem is small enough to solve by library design | Write functions that are non-trivially pure; curate prompts to avoid trivially equivalent mutations |
| Auto-test generation alongside mutations | Meta's ACH generates targeted tests that engineers review | Changes the demo's teaching moment — the point is that the human must write the missing test | Output survived mutations as "here's what you're missing"; let the fixed-tests branch show the human-written solution |
| Web UI / dashboard | Makes output prettier | Scope creep; inconsistent with "Claude Code skill you can run today" message | Rich terminal output with ANSI formatting is sufficient |
| Mutation of test files (mutation testing the tests themselves) | "Full mutation coverage" | Out of scope; confuses the audience about what's being mutated | Mutate only the library source files; test files are the oracle |
| Integration with CI (auto-run on PR) | Production-readiness story | Adds infra complexity irrelevant to the demo; the skill is a local tool for the demo | Mention CI integration as a follow-up in the README; don't implement it |

---

## Feature Dependencies

```
[RSpec suite — 100% line coverage, passing green]
    └──required-by──> [mutant gem integration]
                           └──required-by──> [Kill rate / mutation score display]
                                               └──required-by──> [Side-by-side comparison output]

[Date/time utility library]
    └──required-by──> [RSpec suite]
    └──required-by──> [LLM mutation skill — source file to mutate]
    └──required-by──> [mutant gem integration]

[SimpleCov JSON output]
    └──required-by──> [LLM skill — coverage-gap targeting]

[LLM mutation skill — per-mutation RSpec runner]
    └──requires──> [RSpec suite]
    └──requires──> [Source file restoration]
    └──required-by──> [Kill/survive verdict per mutation]
    └──required-by──> [Mutation score summary]
    └──required-by──> [Cost reporting]

[Kill rate (mutant)] ──enables──> [Side-by-side comparison output]
[Mutation score (LLM skill)] ──enables──> [Side-by-side comparison output]

["Fixed tests" branch]
    └──requires──> [Survived-mutation list from both tools]
    └──required-by──> [README shot list / narration script — Act 2 close]
```

### Dependency Notes

- **Library before everything:** The date/time utility library is the foundation. Nothing else can be built until the six functions are written and their deliberate weaknesses are designed in — the weakness pattern determines which mutations survive.
- **Weak tests before strong tests:** The 100%-coverage-but-weak RSpec suite must be written and verified to be weak before running either tool. If tests are written test-first with real assertions, the demo loses its premise.
- **SimpleCov before LLM skill targeting:** Coverage-gap targeting in the skill requires SimpleCov to be configured and producing JSON output. This is a low-complexity dependency but must be sequenced correctly.
- **mutant before comparison:** The side-by-side comparison table can only be written after both tools have run and their outputs are captured. The comparison is a synthesis artifact, not a standalone feature.
- **Fixed-tests branch last:** The "fixed" state should be built last, after all mutations from both tools are known. Writing it prematurely risks missing a mutation that was discovered later.

---

## MVP Definition

### Launch With (v1)

Minimum to make the demo runnable and narratively complete:

- [ ] Date/time utility library (all 6 functions) — without this nothing else exists
- [ ] 100%-covered, deliberately weak RSpec suite — the premise of the demo
- [ ] `mutant` gem integration with survived-mutation report — the traditional baseline
- [ ] LLM mutation skill: mutation generation + RSpec runner + kill/survive verdict + mutation score — the headline novelty
- [ ] Plain-English mutation descriptions in skill output — what separates this from operator-based tools
- [ ] "Fixed tests" branch showing all mutations killed — narrative close
- [ ] README with demo flow, commands, and narration script — recording artifact

### Add After Validation (v1.x)

- [ ] Side-by-side comparison table (mutant vs LLM skill) — add once both tools have been run end-to-end and outputs are stable; comparison format may need iteration
- [ ] Cost reporting in LLM skill — add once token counting is confirmed working; low complexity, high demo impact
- [ ] SimpleCov-based coverage-gap targeting in LLM skill — add after basic skill works; improves mutation targeting but skill is functional without it

### Future Consideration (v2+)

- [ ] Configurable mutations-per-function flag — defer; default of 3 covers demo needs
- [ ] CI integration example — document in README as future work
- [ ] Multi-codebase proof of skill reusability — explicitly out of scope for v1 per PROJECT.md

---

## Feature Prioritization Matrix

| Feature | Demo Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Date/time library (6 functions) | HIGH | LOW | P1 |
| Weak 100%-covered RSpec suite | HIGH | LOW | P1 |
| `mutant` gem integration + report | HIGH | MEDIUM | P1 |
| LLM skill: generate + run + verdict | HIGH | HIGH | P1 |
| Plain-English mutation descriptions | HIGH | MEDIUM | P1 |
| "Fixed tests" branch | HIGH | MEDIUM | P1 |
| README + narration script | HIGH | MEDIUM | P1 |
| Side-by-side comparison output | HIGH | MEDIUM | P2 |
| Cost reporting in skill | MEDIUM | LOW | P2 |
| SimpleCov coverage-gap targeting | MEDIUM | MEDIUM | P2 |
| Configurable mutations-per-function | LOW | LOW | P3 |
| Dual-audience narration markers in README | MEDIUM | LOW | P2 |

---

## Competitor / Reference Analysis

This project is a demo, not a product, so "competitors" are existing mutation testing tutorials and demos.

| Feature | Existing tutorials (PIT, MutPy, Stryker) | Meta's ACH system | This demo |
|---------|------------------------------------------|-------------------|-----------|
| Mutation type | Operator-based (relational, arithmetic) | Domain-specific, LLM-generated | Both, side-by-side |
| Output format | Terminal diffs + score | Generated test suggestions | Terminal diffs + plain-English descriptions + score |
| "Coverage is a lie" framing | Sometimes implied | Not a focus | Central thesis |
| Audience | Engineers | Meta engineers | Mixed engineers + leadership |
| LLM integration | None | Full (ACH system) | Claude Code skill (Sonnet 4.6) |
| Cost transparency | N/A | N/A | Per-run cost reporting |
| Fix demonstration | Rarely shown | Auto-generated (ACH) | Human-written "fixed tests" branch |
| AI-era angle | Absent | Privacy/compliance focus | "AI-generated tests can be weak too" |

Most existing demos (greg.dev FizzBuzz, OpenDSA examples, Microsoft .NET guide) show the mutation testing concept clearly but stop at "here's what survived." This demo adds the LLM novelty layer, the AI-era framing, and the dual-audience narration — none of which appear in existing tutorials.

---

## Sources

- [Meta Engineering: LLMs Are the Key to Mutation Testing and Better Compliance](https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/) — Meta's ACH system design and results (Sept 2025)
- [InfoQ: Meta Applies Mutation Testing with LLM to Improve Compliance Coverage](https://www.infoq.com/news/2026/01/meta-llm-mutation-testing/) — ACH deployment results and 73% test acceptance rate (Jan 2026)
- [arXiv 2406.09843: A Comprehensive Study on Large Language Models for Mutation Testing](https://arxiv.org/html/2406.09843v2) — LLM vs traditional operator comparison; 93.4% vs 74.4% real-bug detection; 57 AST node types vs 2
- [arXiv 2603.24560: Boosting LLMs for Mutation Generation (SMART)](https://arxiv.org/html/2603.24560v1) — RAG-augmented mutation generation; 92.61% real-bug detection rate
- [mutant gem GitHub](https://github.com/mbj/mutant) — Output format, RSpec integration, diff display, session history
- [Mutation Testing with Ruby — Dave Russell, Medium](https://medium.com/@dave_russell/mutation-testing-with-ruby-deb77bbd856b) — Ruby-specific mutation operator behavior
- [gerg.dev mutation testing demo](https://gerg.dev/2019/09/mutation-testing-demo/) — Narrative structure: cautionary tale framework, before/after comparison
- [AppsFlyerEngineering: Tests Coverage is Dead](https://medium.com/appsflyerengineering/tests-coverage-is-dead-long-live-mutation-testing-7fd61020330e) — Nuclear reactor boundary example; stakes-driven demo framing
- [GoCardless business gem](https://github.com/gocardless/business) — Business-day calculation patterns in Ruby
- [Code of Matt: Beware the Edge Cases of Time](https://codeofmatt.com/beware-the-edge-cases-of-time/) — DST spring-forward/fall-back non-existent and ambiguous times
- [Astrails: Leap Years and Testing](https://astrails.com/blog/2013/07/29/leap-years-and-testing) — Feb 29 birthday `age_in_years` bug pattern
- [Mutation Testing: How to Ensure Code Coverage Isn't a Vanity Metric — Codecov](https://about.codecov.io/blog/mutation-testing-how-to-ensure-code-coverage-isnt-a-vanity-metric/) — "100% coverage, 4% mutation score" example

---
*Feature research for: Ruby mutation-testing demo (Perforce/PE internal)*
*Researched: 2026-05-26*
