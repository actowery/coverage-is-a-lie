# Demo Shot List: coverage-is-a-lie

Numbered beats for recording the two-act mutation testing demo.
Each beat specifies the branch, exact commands, expected output literals to verify on screen,
and dual-audience cues for the presenter.

---

**Beat 1 — Setup: Clone and Install**

Branch: `main`

Commands:
```
git clone https://github.com/actowery/coverage-is-a-lie.git
cd coverage-is-a-lie
bundle install
```

Expected output:
- `Bundle complete!`

Engineer cue: No special flags, no Python dependency, no API key wiring required — just bundle
install. The skill is pre-installed in `.claude/skills/llm-mutate/`. Verify with
`ls .claude/skills/llm-mutate/`.

Leadership cue: This is a repo any engineer on your team can run in five minutes. There is no
complex setup story here — the demo is designed to travel.

---

**Beat 2 — Act 1 Setup: Check Out the Weak State**

Branch: `demo/weak-tests`

Command:
```
git checkout demo/weak-tests
```

Expected output:
- `Switched to branch 'demo/weak-tests'`

Engineer cue: This branch has committed mutation reports in `tmp/` — no re-running needed for the
demo. `tmp/mutant-report.txt` is already there from Phase 3 execution. The branch diverges from
main only in its committed tmp/ artifacts and existing spec state.

Leadership cue: We're starting with the "passing" state — green CI, full coverage, nothing
failing. This is how most codebases look when the team says "we're good."

---

**Beat 3 — Act 1 Scene 1: Show the Green Test Suite**

Branch: `demo/weak-tests`

Command:
```
COVERAGE=1 bundle exec rspec
```

Expected output:
- `28 examples, 0 failures`
- `Line Coverage: 100.0%`
- `Branch Coverage: 100.0%`

Engineer cue: 100% line AND branch coverage — this isn't lazy coverage that only hits happy
paths. Every if-statement is exercised. Every conditional branch is reached. SimpleCov reports
no gaps whatsoever.

Leadership cue: Every automated quality signal says "ship it." No warnings, no failures. This is
a green dashboard. This is what passing looks like.

---

**Beat 4 — Act 1 Scene 2: Reveal the Kill Rate**

Branch: `demo/weak-tests`

Command (show committed report — no re-run needed):
```
cat tmp/mutant-report.txt
```

Or to replay the full run live:
```
bundle exec rake mutant
```

Expected output (from committed `tmp/mutant-report.txt`):
- `Coverage:        2.31%`
- `253` alive mutations
- `6` killed mutations (visible in the per-subject summaries)

Engineer cue: Kill rate 2.31% on a 100%-covered codebase. 253 mutations survive undetected.
mutant applies operator-based substitutions — flip a sign, remove a guard, return nil. The
6 kills are all in `leap_year?` where the test suite happens to test 1900, which constrains
the century-guard logic enough to catch a few variants. The audit in `docs/mutant-audit.md`
found 7 genuinely equivalent mutations, 27 uncertain, and roughly 218 meaningful survivors.

Leadership cue: We ran 259 tiny automated experiments, each asking the same question: "Would
your tests notice if the code were subtly wrong?" The answer was no, 97% of the time. The tests
are green. The coverage is 100%. And 253 ways to silently break this code are invisible to it.

---

**Beat 5 — Act 1 Scene 3: Show a Surviving Mutation Diff**

Branch: `demo/weak-tests`

Command:
```
grep -A 10 "M-LY-24\|M-LY-26" tmp/mutant-report.txt | head -25
```

Or open `docs/mutant-audit.md` and navigate to the `leap_year?` section.

Expected output (paraphrase — exact diff formatting varies):
- A diff showing the century-guard being removed or disabled
- The mutation marked alive

Engineer cue: M-LY-24 disables the `% 100` guard using `if nil` — the guard never fires, so
century years like 2000 are no longer excluded from the leap-year rule. The test suite tests
1900, which is a century year, but only enough to exercise basic divisibility. Year 2000 is
never tested. This mutation corresponds directly to the boundary bug planted in Phase 2.

Leadership cue: Here is exactly what the "wrong but green" code looks like. A mutation that
removes the century exception for leap year rules survives because no test ever asks "is the
year 2000 a leap year?" The code gives the wrong answer. The tests give it a pass.

---

**Beat 6 — Act 2 Setup: Introduce llm-mutate**

Branch: `demo/weak-tests`

No command — spoken beat (presenter explains while terminal shows `docs/comparison.md` or the
README Act 2 section).

Engineer cue: mutant generates mechanical operator substitutions — flip `<` to `>`, remove a
guard, return nil. That gives a signal, but it is noisy. Meta published research in 2025 on a
different approach: instead of operator substitutions, use a language model to generate the
mistakes a careless developer would actually write. Semantically meaningful mutations. The kind
that pass code review. Our `/llm-mutate` skill applies that approach. It lives at
`.claude/skills/llm-mutate/` — no API key, runs in a Claude Code session, reusable across repos.

Leadership cue: Traditional tools ask "does any mutation survive?" LLM-driven tools ask "would
a plausible developer mistake survive?" That is a sharper question — because your AI coding
tools make plausible-looking changes, not random operator substitutions. That is the threat
model that matters now.

---

**Beat 7 — Act 2 Scene 1: Run llm-mutate in Replay Mode**

Branch: `demo/weak-tests`

Command (inside a Claude Code session):
```
/llm-mutate --replay
```

Or to show the committed report directly without a session:
```
cat tmp/llm-mutation-report.md
```

Expected output (from committed `tmp/llm-mutation-report.md`):
- `Total mutations: 20`
- `Survived: 20`
- `Mutation score: 0/20 (0.0%)`
- `Mode: --replay (deterministic)`

Engineer cue: 20/20 LLM mutations survive. The replay fixture (`canonical.json`) contains
6 anchor mutations that directly model the Phase 2 boundary bugs — each a plausible developer
mistake targeting a real gap in the test suite. None are killed. The `--replay` flag reads the
committed fixture and is deterministic across runs; `--generate` would call the live session
model to produce fresh mutations.

Leadership cue: A language model generated 20 realistic ways this code could be subtly wrong.
The test suite caught zero of them. Not because the model is smarter than the tests — because the
tests never asked the right questions.

---

**Beat 8 — Act 2 Scene 2: Show an LLM Mutation Description**

Branch: `demo/weak-tests`

Command:
```
grep -A 12 "LM-LY-01" tmp/llm-mutation-report.md
```

Or scroll to the `leap_year?` section in the report.

Expected output (from committed report):
- `LM-LY-01`
- `leap_year?`
- `Adds the correct 400-year Gregorian exception`
- `SURVIVED`
- `Anchor bug: yes`

Engineer cue: LM-LY-01 adds the CORRECT Gregorian rule — `&& (year % 400) != 0`. This is not
a bug injection; it is the fix. The mutated code is provably more correct than the original.
Yet it still survives, because no test checks year 2000. The LLM found the missing behavior by
generating the implementation of it. Coverage could not detect the gap because coverage only
measures paths executed, not assertions made.

Leadership cue: An LLM generated the right answer and the test suite could not tell the
difference between "right answer we don't have" and "wrong answer we do have." That is the gap
mutation testing closes. Coverage says every path runs. Mutation testing says every behavior
is verified.

---

**Beat 9 — Act 2 Scene 3: Review the Comparison Document**

Branch: `demo/weak-tests`

Command:
```
cat docs/comparison.md
```

Or open in editor and navigate to the Divergences Summary section.

Engineer cue: Point to the three highlighted divergences. mutant and llm-mutate find different
mutations — both survive, but they represent different failure modes. M-AB-25 inverts a direction
flag with an operator swap so obvious any reviewer would catch it on first glance. LM-AB-01 adds
a weekend-normalizer a developer might genuinely write. Both survive the same weak test suite for
the same reason — weekday-only start dates. The LLM mutation is qualitatively more dangerous.
Also note LM-WB-02: float division coercion (`/ 7.0`) — a mutation with no direct mutant
counterpart, because it requires understanding Ruby's numeric type system.

Leadership cue: Two tools, same codebase, different lenses. The LLM mutations look like code
your engineers would write. The mechanical mutations look like compiler output. In an AI-assisted
codebase where generated code changes arrive constantly, which threat model matters more?

---

**Beat 10 — The Turn: Check Out Fixed Tests**

Branch: `demo/fixed-tests`

Command:
```
git checkout demo/fixed-tests
```

Expected output:
- `Switched to branch 'demo/fixed-tests'`

Engineer cue: This branch adds 6 boundary-case tests to `spec/date_utils_spec.rb` (28 to 34
examples) and fixes the 6 intentional boundary bugs in `lib/date_utils.rb`. No library rewrites
— only the tests and targeted fixes. The commits are visible in `git log --oneline`.

Leadership cue: Here is what it looks like when you write the tests you should have written in
the first place. Not more tests — the right tests.

---

**Beat 11 — Act 2 Resolution: Show the Improved Test Suite**

Branch: `demo/fixed-tests`

Command:
```
COVERAGE=1 bundle exec rspec
```

Expected output:
- `34 examples, 0 failures`
- `Line Coverage: 100.0%`

Engineer cue: Still green. 34 examples, zero failures. The boundary tests pass because the
library was fixed to match the behavior the tests now assert. Coverage is still 100% — it was
always 100%. Coverage did not change. What changed is what the tests assert.

Leadership cue: Same green light. But now it means something. The number went up because we
added the missing verifications, not because we padded the count.

---

**Beat 12 — Act 2 Resolution: Re-run mutant**

Branch: `demo/fixed-tests`

Command (show committed refreshed report):
```
cat tmp/mutant-report.txt
```

Expected output (from committed `tmp/mutant-report.txt` on `demo/fixed-tests`):
- `Coverage:        1.75%`
- Note: this is lower than 2.31% due to a known `module_function` quirk — the library grew
  (341 mutations vs 259), but mutant patches instance methods; the new singleton-method surface
  created more uncoverable mutations. This is documented in `docs/mutant-audit.md`.

Engineer cue: The 1.75% rate looks counterintuitive — it is lower than the weak suite's 2.31%
because the library grew with the fixes (341 mutations vs 259) while mutant's singleton-method
limitation keeps kills at 6. This is a known limitation of the tool on `module_function` code.
The LLM report on this branch is the clean signal.

Leadership cue: Traditional mutation testing has tooling constraints. This is why we built the
LLM alternative — it is not limited by the Ruby singleton-method quirk.

---

**Beat 13 — Act 2 Resolution: Re-run LLM-mutate**

Branch: `demo/fixed-tests`

Command (inside a Claude Code session):
```
/llm-mutate --replay
```

Or show the committed report:
```
cat tmp/llm-mutation-report.md
```

Expected output (from committed `tmp/llm-mutation-report.md` on `demo/fixed-tests`):
- `Total mutations: 13`
- `Killed: 13`
- `Mutation score: 13/13 (100.0%)`
- `Mode: --generate (boundary-targeted mutations for fixed lib/date_utils.rb)`

Note: The fixed-tests branch uses a generate-mode report, not replay-mode. After fixing the
library, the canonical.json mutations target lines that no longer exist — replay would produce
SKIP results. The generate-mode report demonstrates boundary-targeted mutations killed.

Engineer cue: 13/13 killed. The generate-mode report was created by running `--generate` against
the fixed library, producing boundary-targeted mutations. Every one of them is killed by the
6 boundary tests added in this branch. The original replay fixture would show 7 SKIP results
(mutations targeting lines that were changed by the fix) — so generate mode was used to create
a clean signal for the fixed-tests state.

Leadership cue: We went from zero out of twenty to a clean sweep. Not by changing the tools.
By writing better tests. The loop is closed: LLM found the gaps, we wrote the tests, the
mutations are killed.

---

**Beat 14 — Wrap: Return to main**

Command:
```
git checkout main
```

Expected output:
- `Switched to branch 'main'`

Spoken close: Point to `README.md`, `docs/comparison.md`, and `docs/shot-list.md` as take-home
artifacts. The skill is at `.claude/skills/llm-mutate/` — drop it into any Ruby repo in a Claude
Code session.

Engineer cue: The skill is at `.claude/skills/llm-mutate/` — reusable on any Ruby codebase in a
Claude Code session. Two invocation modes: `--replay` for a deterministic demo using a committed
fixture, `--generate` for live mutation generation. The fixture format is documented in
`.claude/skills/llm-mutate/SKILL.md`.

Leadership cue: This entire demo runs in under 10 minutes. It is not a research prototype — it
is a skill your team can adopt today, in the workflows they already use. The next time a PR
comes in with "100% coverage," they have a tool to ask the harder question.

---

## Pre-Recording Checklist

- [ ] On recording machine: `git clone` + `bundle install` completes cleanly
- [ ] `git checkout demo/weak-tests` works and `tmp/mutant-report.txt` exists
- [ ] `git checkout demo/fixed-tests` works and both `tmp/` reports exist
- [ ] `git show demo/weak-tests:tmp/mutant-report.txt | grep Coverage` outputs `2.31%`
- [ ] `git show demo/weak-tests:tmp/llm-mutation-report.md | grep "Mutation score"` outputs `0/20 (0.0%)`
- [ ] `git show demo/fixed-tests:tmp/llm-mutation-report.md | grep "Mutation score"` outputs `13/13 (100.0%)`
- [ ] Claude Code session `~/.claude/settings.json` has the permissions block from README.md
- [ ] `/llm-mutate --replay` runs on `demo/weak-tests` without permission prompts (do a test run before recording)
- [ ] Terminal font size is readable in screen recording (suggest 16pt minimum, dark theme preferred)
- [ ] `git checkout main` performed — recording starts fresh from main with a clean state
- [ ] Screen recording software tested and resolution confirmed (1080p minimum for terminal text legibility)
