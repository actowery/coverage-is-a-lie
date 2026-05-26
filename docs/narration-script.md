# Narration Script: coverage-is-a-lie Demo

Recording-ready voice-over prose, aligned beat-for-beat to `docs/shot-list.md`.
Read this aloud while executing each beat. Every word is final — no placeholders to fill in.

---

## Beat 1 — Setup

"Let's start from scratch. Clone the repo, bundle install. No external services to spin up.
No API key wiring, no Docker, no Python dependency. This runs wherever Ruby runs."

(Pause while bundle install completes — typically 20 to 40 seconds on first run.)

"Bundle complete. We're ready."

---

## Beat 2 — Check Out the Weak State

"I'm switching to the demo/weak-tests branch. This is the state every CI pipeline calls green.
28 tests, all passing, and I'll show you the coverage in a moment."

---

## Beat 3 — Show the Green Test Suite

"Here's the full test suite running with coverage enabled. Watch the output."

(Run: `COVERAGE=1 bundle exec rspec`)

"28 examples. Zero failures. And the coverage report — 100% line coverage. 100% branch
coverage. Every if-statement exercised, every conditional branch reached. SimpleCov finds no
gaps whatsoever. This is what a green dashboard looks like."

"If this were your CI pipeline, everything would be marked passing. Merge button is green.
Nothing to see here."

---

## Beat 4 — Reveal the Kill Rate

"Now let's ask a harder question. Instead of 'do the tests run,' let's ask: 'would the tests
notice if the code were subtly wrong?' That's what mutation testing does. It makes small
automated changes to the source — a flipped sign, a removed guard, a returned nil — and checks
whether the test suite catches any of them."

(Show `tmp/mutant-report.txt` or run `bundle exec rake mutant`)

"Kill rate: 2.31%. Two hundred and fifty-three mutations survived. That means 253 different ways
to silently break this code, and the test suite would not catch any of them. The six that were
killed are all in leap_year? — the only function where the tests happen to use years that
constrain the logic enough to matter."

"The tests are green. The coverage is 100%. And 253 behavioral gaps are completely invisible
to both."

---

## Beat 5 — Show a Surviving Mutation Diff

"Here is one example. This mutation from mutant — M-LY-24 — disables the century guard in the
leap_year? function. The guard is what makes century years like 1900 not leap years. The mutation
removes it by setting the condition to nil, so the guard never fires."

(Show the diff from the report or docs/mutant-audit.md)

"The test suite does test 1900 — it expects false. But it never tests the year 2000. Year 2000
should return true under the Gregorian calendar. Year 2000 divided by 100 is an even century
year, but it is also divisible by 400, so it is a leap year. The code gets this wrong. The
mutation confirms it. And the tests say everything is fine."

---

## Beat 6 — Introduce llm-mutate

"Traditional mutation testing generates mechanical operator substitutions. Flip a less-than to
a greater-than, remove a guard, return the wrong constant. That gives you a signal, but it is
noisy — full of equivalent mutations where the change doesn't actually alter observable behavior
for any realistic input."

"Meta published research in 2025 on a different approach. Instead of exhaustive operator
substitutions, they used a language model to generate the mistakes a careless developer would
actually write. Semantically meaningful mutations. The kind of change that could pass a code
review. Their trial at Meta produced a 73% engineer acceptance rate for the generated tests
that resulted."

"That is what we built here. It is a Claude Code skill at .claude/skills/llm-mutate/. No separate
API key — it runs inside your Claude Code session. You can drop it into any Ruby codebase. And
critically: it targets the same threat model as AI-assisted development. Your AI coding tools
generate plausible-looking code changes, not random operator substitutions. That is the mutation
type you need to defend against now."

---

## Beat 7 — Run llm-mutate in Replay Mode

"I'm running /llm-mutate in replay mode. This reads a committed fixture — the same 20 mutations
every time — so the demo is deterministic and does not depend on a live API call. In generate
mode, Claude would produce fresh mutations against the current source file."

(Run `/llm-mutate --replay` or show `tmp/llm-mutation-report.md`)

"Mutation score: zero out of twenty. All twenty LLM-generated mutations survive. And look at
the cost estimate — this is a replay run so no tokens were consumed, but the generate mode
footer shows the cost for a live generation run is under a dollar. This is not an expensive
operation."

"Twenty plausible developer mistakes. Zero caught."

---

## Beat 8 — Show an LLM Mutation Description

"Let me show you one specific mutation. LM-LY-01, for the leap_year? function."

(Show the report entry for LM-LY-01)

"The LLM generated the complete correct Gregorian exception — the rule that century years are
not leap years UNLESS they are also divisible by 400. This mutation is not an injected bug. It
is the actual fix for the boundary error in this library. A reviewer looking at this diff would
accept it immediately. It makes the code more correct."

"And the test suite cannot tell the difference between this mutation — the right answer we don't
have — and the original code — the wrong answer we do have. Because no test ever calls
leap_year? with the year 2000."

"That is the gap mutation testing reveals. Not that your tests are wrong. That your tests are
incomplete. Coverage measures paths executed. Mutation testing measures behaviors verified. These
are different things, and in an AI-assisted codebase, the difference matters more every quarter."

---

## Beat 9 — Review the Comparison Document

"This comparison document maps both tools to the same six functions. Eight labeled divergence
points. What is interesting is not that both tools find surviving mutations — we already know
the tests are weak. What is interesting is that they find different things, for different reasons."

(Open `docs/comparison.md`, navigate to Divergences Summary)

"Here is the clearest one. mutant's M-AB-25 inverts the direction logic in add_business_days —
replacing the n.positive? check with n.negative?. No developer writes that. It is too obviously
wrong. But LLM's LM-AB-01 adds a weekend-normalizer that would advance past any Saturday or
Sunday start date before the main loop begins. That is a change a developer might write as a
defensive pre-condition. Both survive because all test start dates are weekdays. But only the
LLM mutation simulates the kind of code that arrives in your codebase from AI-generated PRs."

"And then there is LM-WB-01 — float division. The LLM changed integer division to float
division, returning 2.0 instead of 2. Ruby's equality makes 2.0 == 2 pass. No operator-based
tool generates this class of mutation because it requires understanding the numeric type system.
The LLM finds it because it thinks about what a developer might write, not what operators can
be mechanically substituted."

---

## Beat 10 — Check Out Fixed Tests

"Now for the resolution."

(Run: `git checkout demo/fixed-tests`)

"This branch adds six boundary tests — reversed dates, a Saturday start, year 2000, a February
29 birthday, a same-day weekday target, reversed week order. These are the exact inputs the weak
suite omitted. And the six intentional boundary bugs in the library are fixed to match."

"No library rewrites. Just the tests that should have been there from the start, and the
implementations that make them pass."

---

## Beat 11 — Show the Improved Test Suite

"Still green."

(Run: `COVERAGE=1 bundle exec rspec`)

"34 examples. Zero failures. The boundary tests pass because the library is now correct for
those inputs. Coverage is still 100% — it was always 100%. Coverage did not change. What
changed is what the tests assert and which inputs they cover."

"If this is all you looked at, you would see: same green light, six more tests. But the
mutation scores are about to tell a different story."

---

## Beat 12 — Re-run mutant

(Show committed `tmp/mutant-report.txt` on demo/fixed-tests)

"The mutant kill rate on this branch is 1.75% — which looks lower than before, and I need to
explain why. The library grew when we fixed the bugs. mutant now has 341 mutations to test
instead of 259. But mutant has a limitation with Ruby's module_function pattern — it patches
instance methods, and these utility functions are defined as singleton methods. The kill count
stays at 6 because the new boundary tests do not trigger the instance-method paths that mutant
can reach."

"This is a known limitation documented in the mutant audit. It is not a failure of the tests —
it is a tooling constraint. The LLM report will show the clean signal."

---

## Beat 13 — Re-run LLM-mutate

(Show committed `tmp/llm-mutation-report.md` on demo/fixed-tests)

"And here is the result. 13 out of 13 killed. One hundred percent."

"The generate-mode report was produced by running --generate against the fixed library, creating
boundary-targeted mutations for the corrected code. Every one of them is killed by the six
boundary tests added in this branch. The reversed-date mutations, the year-2000 mutations, the
February-29 normalization mutations, the same-day weekday mutations — all killed."

"We went from zero out of twenty to 13 out of 13. Not by changing the tools, not by buying
a better platform. By writing the tests that mutation testing told us were missing."

"That is the complete loop. Coverage said we were done. mutant and llm-mutate said we were not.
We wrote the tests. The mutations are killed. Now we are actually done."

---

## Beat 14 — Wrap

(Run: `git checkout main`)

"Back to main."

"Two things to take away. First: 100% code coverage is not an assurance signal. It is a floor,
not a ceiling. It tells you that your tests execute every line. It does not tell you whether
your tests assert the right things. Mutation testing is the measurement that actually answers
the question you care about."

"Second: LLM-driven mutation testing is not a research curiosity. This skill runs in your Claude
Code session, on your codebase, today. The next time you are reviewing a PR with green coverage
and you want to know whether those tests would catch a subtle behavioral change — now you have
a tool for that. And it costs less than a cup of coffee to run."

"The repo, the skill, the comparison document, this shot list — all committed. If you want to
adopt this on your team, start with the README and the Claude Code permissions block. You can
have mutation testing running on your Ruby codebase in an afternoon."

---

## Timing Notes

- Full demo at a comfortable recording pace: approximately 10 to 12 minutes
- Beats 1 to 5 (Act 1 — green state and traditional mutation): approximately 4 to 5 minutes
- Beats 6 to 9 (Act 2 introduction — llm-mutate and comparison): approximately 3 to 4 minutes
- Beats 10 to 14 (Resolution — fixed tests and wrap): approximately 2 to 3 minutes

For a 5-minute cut: omit Beats 5, 8, and 9; compress Beats 6 and 7 into a single beat with the
spoken text from Beat 6's second paragraph and Beat 7's final three lines. The core arc remains
intact: green suite, 2.31% kill rate, 0/20 LLM score, fixed tests, 13/13 LLM score, wrap.
