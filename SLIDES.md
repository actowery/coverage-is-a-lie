---
marp: true
theme: default
class: invert
paginate: true
header: "100% Coverage Is a Lie"
footer: "github.com/actowery/coverage-is-a-lie"
style: |
  section { font-size: 26px; }
  section h1 { font-size: 38px; }
  table { font-size: 22px; }
  pre, code { font-size: 20px; }
  section.dense { font-size: 22px; }
  section.dense table { font-size: 19px; }
  section.dense pre, section.dense code { font-size: 17px; }
  blockquote { border-left: 4px solid #888; padding-left: 12px; color: #ddd; }
---

# 100% Coverage Is a Lie

## Why LLM-driven mutation testing is the assurance layer your CI is missing

Adrian Towery · Perforce / Puppet Enterprise
2026

---

# The trap we all walked into

- **Code coverage** became the proxy for "tested"
- **Green CI + 100% line/branch** became the proxy for "safe to ship"
- Both are **easy to game** — even unintentionally
- AI-generated code makes this worse: tests that hit every line without verifying behavior

> "Coverage tells you what code ran. It does not tell you what your tests would notice if the code were wrong."

---

# What we're going to do (in 6 minutes)

1. Show a Ruby library with **100% line + branch coverage**
2. Show that `mutant` (the traditional tool) reports a **96.52% kill rate** — and why that's not the win it sounds like
3. Show that an LLM-driven mutation skill — Meta's approach — **kills 0 of 20**
4. Add six targeted boundary tests
5. Watch the right gaps close

Same library. The diff is six tests written from a plain-English report.

---

# The Meta thesis we're going to walk

From the FSE 2025 paper, *Mutation-Guided LLM-based Test Generation at Meta*:

> "Rule-based mutation operators are ill-suited to the task of generating realistic faults. They produce large volumes of mutants indiscriminately, many semantically equivalent to the original code, overwhelming test infrastructure and developer workflows."

This deck demonstrates that statement on a 72-line Ruby library, with `mutant` standing in for the 1990s-style operator approach and `/llm-mutate` standing in for the Meta-style LLM approach.

---

# Act 1 — Beat 1: the library

`lib/date_utils.rb` — six pure-Ruby functions:

- `days_between(start, end)`
- `add_business_days(date, n)`
- `leap_year?(year)`
- `age_in_years(birthdate, as_of:)`
- `next_occurrence_of_weekday(from, weekday)`
- `weeks_between(start, end)`

Each has subtle boundary behavior: leap years, DST-adjacent math, negative durations, Feb 29, same-day weekday.

---

# Act 1 — Beat 1: the suite

`spec/date_utils_spec.rb`

- **28 tests**, real `expect(x).to eq(y)` assertions
- Looks like normal first-pass coverage to a reviewer
- Passes under both `TZ=UTC` and `TZ=America/New_York`

```
$ bundle exec rspec
28 examples, 0 failures
```

```
$ bundle exec rake coverage
Line Coverage:   100.0% (27/27)
Branch Coverage: 100.0% (13/13)
```

---

# 🟢 SimpleCov says we're good

![bg right contain](https://placehold.co/600x400/22c55e/white?text=100%25+Green)

100% line.
100% branch.
0 failures.

**Ship it?**

---

# Act 1 — Beat 2: enter `mutant`

Operator-based mutation testing. Mutate one operator at a time, re-run the suite, see if anything fails.

```
$ bundle exec mutant run --integration rspec DateUtils
...
Mutations:    259
Kills:        250
Alive:          9
Timeouts:      11
Coverage:    96.52%
```

**100% line coverage. 96.52% mutant kill rate.**

By traditional mutation testing standards, this suite looks strong.

---

# But what does mutant actually catch?

The 9 survivors include things like this — in `days_between`:

```diff
 def days_between(start_date, end_date)
-  (end_date - start_date).to_i
+  (end_date - start_date)
 end
```

Date subtraction returns `Rational(7,1)`. `.to_i` is `7`. **And `Rational(7,1) == 7` is true.**

The mutation changed the *return type*, not any observable result.

**Equivalent mutant.** Indistinguishable from the original under all inputs. ~10–15% of operator mutations are equivalent — mathematically undecidable to detect.

---

# Meta on why this is structural, not a bug

From the *Engineering at Meta* post, September 2025:

> "Traditional mutation testing has seen limited adoption due to excessive mutant counts, high computational costs, and the presence of equivalent mutants that add little value."

> "These [rule-based operators] generated large volumes of mutants indiscriminately, many semantically equivalent to the original code, overwhelming test infrastructure and developer workflows."

**96.52% kill rate is real. It is also not what matters.**

What matters: what kinds of bugs slip through *any* operator-based pass?

---

# Act 2 — Beat 3: `/llm-mutate`

Custom Claude Code skill. Generates mutations the way a careless developer or an AI assistant writes code:

- off-by-one boundaries
- missing edge-case handling
- plausible-but-wrong refactors
- equivalent-looking semantic divergence (Rational vs Integer, `==` vs `eq`)

This is the same approach Meta's ACH system takes — **fewer, more realistic, highly specific mutants targeted at particular fault classes.**

---

# `/llm-mutate --replay` on the weak suite

```
$ /llm-mutate --replay
Total mutations:  20
Killed:           0
Survived:         20
Mutation score:   0/20 (0.0%)
```

**Zero caught.** Every mutation a plausible developer mistake, every one in plain English.

| Layer | Score |
|-------|-------|
| SimpleCov line coverage | 100% |
| SimpleCov branch coverage | 100% |
| `mutant` (operator) | 96.52% |
| `/llm-mutate` (semantic, Meta-style) | **0/20** |

---

# The single best mutation: LM-LY-01

The LLM mutated `leap_year?` like this:

```diff
 def leap_year?(year)
   return false unless (year % 4).zero?
-  return false if (year % 100).zero?
+  return false if (year % 100).zero? && (year % 400) != 0
   true
 end
```

The LLM **fixed the intentional bug** — added the Gregorian 400-year exception.

**The fix still survives.** Because no test in our suite checks year 2000.

Coverage was blind. Mutant was blind. Semantic LLM mutation surfaced the gap in plain English.

---

<!-- _class: invert dense -->

# The report IS the test backlog

Each surviving mutation **tells you what test is missing**:

| Survivor | What the LLM said | Test you write |
|----------|-------------------|----------------|
| LM-LY-01 | "no test ever checks year 2000" | `leap_year?(2000) == true` |
| LM-DB-03 | "weak suite never passes reversed dates" | `days_between(end, start) == -days_between(start, end)` |
| LM-NO-01 | "no test calls `next_occurrence_of_weekday` with from-date already on the target" | `next_occurrence_of_weekday(monday, :monday) == monday` |
| LM-AI-01 | "no test uses a Feb 29 birthdate" | `age_in_years(Date.new(2000,2,29), as_of: Date.new(2025,2,28))` |
| LM-AB-01 | "all test start dates are weekdays" | `add_business_days(saturday, -3)` |
| LM-WB-03 | "no test passes reversed dates to `weeks_between`" | `weeks_between(end, start)` is positive |

Six anchor survivors → six tests. **The report writes itself.**

---

# Act 3 — Beat 4: write the six tests

```ruby
it "returns true for 2000 (400-year Gregorian exception)" do
  expect(DateUtils.leap_year?(2000)).to be true
end

it "returns 7 days later when from_date is already on the target weekday" do
  monday = Date.new(2024, 1, 1)
  expect(DateUtils.next_occurrence_of_weekday(monday, 1)).to eq(monday + 7)
end
# ... four more, one per anchor mutation ...
```

```
$ bundle exec rspec
34 examples, 0 failures           # 28 weak + 6 new
```

---

# Watch the *right* needle move

| Branch | Mutant kill rate | /llm-mutate score |
|--------|------------------|--------------------|
| `demo/weak-tests` | 96.52% (250/259) | **0/20** |
| `demo/fixed-tests` | 94.42% (322/341) | **13/13 (100%)** |

Mutant barely moves. Operator mutations were already mostly caught — adding boundary tests doesn't help much there because mutant wasn't generating the *kind* of mutations the new tests target.

`/llm-mutate` goes from 0% to 100% — because its mutations are **the same kind** as the bugs the boundary tests now catch.

---

# Coverage is blind. Operator mutation is partly noise.

| Tool | Catches | Misses |
|------|---------|--------|
| SimpleCov | code that *ran* | tests that wouldn't notice if it ran wrong |
| `mutant` | obvious operator swaps | semantic mistakes, equivalent mutants, domain-specific faults |
| `/llm-mutate` | realistic developer mistakes in plain English | exhaustive coverage (by design — fewer, targeted) |

`mutant` + `/llm-mutate` together is the strongest pedagogy.
For ongoing assurance, the Meta argument is: **lead with the LLM approach.**

---

# Why LLM mutation, not operator mutation

Meta's reasons, summarized:

1. **Unrealistic faults.** Operator swaps don't look like real developer mistakes.
2. **Scale.** Operator approaches generate dozens of mutants per class; LLM produces a handful.
3. **Equivalent-mutant noise.** 10–15% of operator mutants are mathematically undecidable.
4. **No targeting.** Operator tools can't express "find privacy faults" or "find boundary bugs."
5. **Reviewer burden.** Plain-English mutations let engineers *evaluate*, not *construct*.

Meta's ACH trial: **73% of LLM-generated tests accepted by engineers, 36% privacy-relevant.**

---

# The workflow, plainly

1. Run the suite. Green. 100% coverage. Feels good.
2. Run `/llm-mutate`. **Mutations survive.**
3. Read the survivor descriptions. **Each names a missing test.**
4. Write the tests. Re-run. **Score climbs.**
5. Set a kill-rate floor in CI. Block PRs that lower it.

You don't need to be a mutation-testing expert to use this. **You need to be able to read English.**

The LLM-driven approach is what makes the descriptions readable.

---

# The thesis, plainly

> 100% coverage is a lie when nothing in your suite would notice if the code were wrong.

> 96% operator-mutation kill rate is a different lie — most of the survivors are noise, and the bugs that hurt most aren't in the mutation set.

> LLM-driven mutation is the AI-era assurance layer: realistic faults, plain-English descriptions, reviewable by humans, generated cheaply.

---

# Why this matters now

- **AI assistants generate code at scale.** New code outstrips human review.
- **Coverage was always a weak signal.** AI-generated tests can hit every line without verifying behavior.
- **Operator mutation testing has known limits** that Meta documented and published in 2025.
- **LLM mutation is cheap and semantic.** ~$0.01 per run. Plain-English descriptions a reviewer can act on.

---

# How to adopt it (this week)

1. **Pick one critical library.** Date math, pricing, auth — anything with boundaries.
2. **Run `/llm-mutate` first.** Semantic mutations are higher signal per mutation; reviewers can read them.
3. **Run `mutant` second**, optional. Confirms you're not missing operator-level holes — but expect the equivalent-mutant noise.
4. **Set a kill-rate floor in CI** for that one library. Tighten over time.

The repo at **`actowery/coverage-is-a-lie`** is the working template.

---

<!-- _class: invert dense -->

# What's in the repo

| Path | Purpose |
|------|---------|
| `lib/date_utils.rb` | Six functions, planted boundary bugs |
| `spec/date_utils_spec.rb` | Weak suite (28 tests, 100% coverage) |
| `baselines/mutant-report.txt` | `mutant` baseline (96.52% kill rate, mostly noise) |
| `baselines/llm-mutation-report.md` | `/llm-mutate` baseline (0/20 on weak branch, 13/13 on fixed) |
| `.claude/skills/llm-mutate/` | The `/llm-mutate` skill — drop-in for any Ruby project |
| `docs/mutant-audit.md` | Classified survivor audit |
| `demo/weak-tests` / `demo/fixed-tests` | Act 1 / Act 3 branches |

---

# Credits & references

- **Meta ACH** — *Mutation-Guided LLM-based Test Generation at Meta*, arXiv 2501.12862 (FSE 2025)
- **Meta engineering blog** — *LLMs Are the Key to Mutation Testing and Better Compliance*, Sep 2025
- **`mutant` gem** — github.com/mbj/mutant
- **SimpleCov** — github.com/simplecov-ruby/simplecov
- **Built with** Claude Code + Claude Sonnet 4.6

Repo: **github.com/actowery/coverage-is-a-lie**

---

# Questions

Take the repo. Fork it. Run it on your codebase.

**100% coverage is a lie. 96% operator-mutation kill rate is a different lie. Read the report and write the six tests.**
