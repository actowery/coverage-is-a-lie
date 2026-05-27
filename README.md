# coverage-is-a-lie

100% code coverage is a lie. 96% operator-mutation kill rate is a different lie. This repo
proves both in three acts and points at the AI-era answer that Meta has already shipped.

The thesis is anchored on Meta's FSE 2025 paper, *Mutation-Guided LLM-based Test Generation
at Meta* (arXiv 2501.12862), which argues that "rule-based mutation operators are ill-suited
to the task of generating realistic faults." This repo demonstrates that statement on a
72-line Ruby library — and shows the LLM-driven alternative working in plain English.

In an AI-assisted codebase, generated tests can hit every line without verifying behavior —
coverage becomes even less trustworthy, not more. LLM-driven mutation testing is the missing
assurance layer.

---

## Quickstart

```bash
git clone https://github.com/actowery/coverage-is-a-lie.git
cd coverage-is-a-lie
bundle install
```

Demo branches created in Phase 5 Plan 02 — see "Demo Branches" below.

```bash
# Run the test suite with coverage
COVERAGE=1 bundle exec rspec

# Run traditional mutation testing (Act 1)
bundle exec rake mutant

# Run LLM-driven mutation testing (Act 2)
# /llm-mutate --replay    ← Claude Code skill, run inside a Claude Code session
```

---

## Act 1: Traditional Mutation Testing (mutant)

Traditional mutation testing applies mechanical operator substitutions to the source code and
asks whether your tests notice. Run mutant and capture the full output to a file:

```bash
bundle exec mutant run --integration rspec DateUtils 2>&1 | tee tmp/mutant-report.txt
```

Or use the convenience Rake task:

```bash
bundle exec rake mutant
```

Live runs write to `tmp/mutant-report.txt` (gitignored). The committed baseline for the demo
branches lives at `baselines/mutant-report.txt`.

**License note:** This repo is open-source. The `.mutant.yml` includes `usage: opensource` which
satisfies the license requirement.

**Expected output shape:**

- Kill rate around `250/259 = 96.52%` on `demo/weak-tests`
- 9 alive (surviving) mutations + 11 timeouts
- Diffs of each surviving mutant

By traditional mutation testing standards, the suite looks strong — but inspecting the 9
survivors reveals the structural problem Meta's ACH paper documents: most are equivalent
mutants or generic syntactic swaps, not real bugs. Example: `(end_date - start_date).to_i`
→ `(end_date - start_date)`. The return type changes from Integer to Rational, but
`Rational(7,1) == 7` is true, so the test suite cannot tell the difference — and no
test suite ever could.

Meta on this:

> "Rule-based mutation operators are ill-suited to the task of generating realistic faults.
> They produce large volumes of mutants indiscriminately, many semantically equivalent to
> the original code, overwhelming test infrastructure and developer workflows."

---

## Act 2: LLM-mutate (Semantic Mutation Testing — Meta's Approach)

LLM-driven mutation testing generates the mistakes a careless developer (or an AI assistant)
would plausibly make — not exhaustive operator substitutions, but semantically meaningful
patches: off-by-one boundaries, missing edge-case handling, plausible-but-wrong refactors.

This is the same approach Meta's ACH (Automated Compliance Hardening) system takes. From their
September 2025 engineering blog: ACH was applied to 10,795 Android Kotlin classes across 7
platforms; it generated 9,095 LLM-driven mutants and 571 hardening tests; 73% of the generated
tests were accepted by engineers, and 36% were judged privacy-relevant.

```bash
/llm-mutate --replay    # deterministic demo mode — reads committed fixture
/llm-mutate --generate  # live generation — uses session's Claude model (Sonnet 4.6 recommended)
```

**Expected output shape:** mutation score `0/20 (0%)` on the weak test suite — all 20
LLM-generated mutations survive. Live runs write `tmp/llm-mutation-report.md` (gitignored);
the committed baseline lives at `baselines/llm-mutation-report.md`.

**The contrast that drives the demo:** the same 28-test suite scores 96.52% against mutant's
operator mutations and 0/20 against the LLM's semantic mutations. The kind of mutation matters
more than how many you generate, and the AI-era kind is what the suite doesn't catch.

See `docs/comparison.md` for a function-by-function comparison of which mutations each tool found
and where they diverge.

**Cost note:** `--generate` mode logs an estimated cost footer (Sonnet 4.6 rates: $3.00/MTok
input, $15.00/MTok output) in the report.

---

## Demo Branches

Two git branches let you switch between the weak-suite and targeted-suite states without
editing files:

- `demo/weak-tests` — green-but-blind state (28 tests, 100% coverage, 96.52% mutant kill rate, 0/20 on /llm-mutate)
- `demo/fixed-tests` — six boundary tests added, four of five intentional bugs patched (34 tests, 94.42% mutant, 13/13 on /llm-mutate)

```bash
# Switch to the weak-tests state and run the demo
git checkout demo/weak-tests
COVERAGE=1 bundle exec rspec          # 28 tests, 100% coverage, all green
bundle exec rake mutant               # 96.52% kill rate — 9 alive, mostly equivalent mutants
# /llm-mutate --replay                # 0/20 LLM mutations killed — the real story

# Switch to the fixed-tests state and observe what the right tests close
git checkout demo/fixed-tests
bundle exec rake mutant               # 94.42% — basically unchanged (operator side was already mostly caught)
# /llm-mutate --replay                # 13/13 = 100% — boundary tests close the semantic gaps

# Return to the development state
git checkout main
```

Mutant moving from 96.52% to 94.42% on the fixed branch is the second pedagogical beat: the
operator side barely moves, because operator mutations were never the missing tests. The LLM
side moving 0 → 100% is the actual fix.

---

## Side-by-Side Comparison

See `docs/comparison.md` for the full comparison table mapping mutations from both tools to the
same six DateUtils functions, with divergence analysis covering where operator-based and
LLM-driven approaches find different things.

---

## Claude Code Permissions for Demo

To run `/llm-mutate` without mid-recording permission prompts, add the following to
`~/.claude/settings.json` before the demo:

```json
{
  "permissions": {
    "allow": [
      "Bash(bundle exec ruby *)",
      "Bash(ruby -c *)",
      "Bash(bundle exec rspec *)",
      "Read(lib/date_utils.rb)",
      "Read(.claude/skills/llm-mutate/fixtures/canonical.json)",
      "Write(tmp/*)"
    ]
  }
}
```

These allow the skill to read the source file, write `tmp/` mutation files, and run
`bundle exec rspec` without pausing for confirmation. Scoped to this repo's commands only.

---

## License

MIT — see [LICENSE](./LICENSE).
