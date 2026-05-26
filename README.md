# coverage-is-a-lie

100% code coverage is a lie. This repo proves it in two acts.

In an AI-assisted codebase, generated tests can hit every line without verifying behavior —
coverage becomes even less trustworthy, not more. Mutation testing is the missing assurance
layer.

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
asks whether your tests notice.

Even with 100% line and branch coverage, the `mutant` gem reveals that the test suite cannot
catch several boundary bugs. Run mutant and capture the full output to a file:

```bash
bundle exec mutant run --integration rspec DateUtils 2>&1 | tee tmp/mutant-report.txt
```

Or use the convenience Rake task:

```bash
bundle exec rake mutant
```

Results are written to `tmp/mutant-report.txt` (gitignored — run locally to reproduce).

**License note:** This repo is open-source. The `.mutant.yml` includes `usage: opensource` which
satisfies the license requirement.

**Expected output shape:**

- Kill rate percentage (e.g. `6/259 = 2.31%`)
- Count of alive (surviving) mutations: 253
- Diffs of each surviving mutant showing exactly what change the test suite failed to catch

The 2.31% kill rate is the central Act 1 evidence: a test suite with 100% line and branch
coverage kills fewer than 1 in 40 mutations. The surviving mutations are not noise — they include
direct behavioral counterparts to every intentional boundary bug planted in the library.

---

## Act 2: LLM-mutate (Semantic Mutation Testing)

LLM-driven mutation testing generates the mistakes a careless developer would plausibly make —
not exhaustive operator substitutions, but semantically meaningful patches.

```bash
/llm-mutate --replay    # deterministic demo mode — reads committed fixture
/llm-mutate --generate  # live generation — uses session's Claude model (Sonnet 4.6 recommended)
```

**Expected output shape:** mutation score 0/20 (0%) on the weak test suite — all 20 LLM-generated
mutations survive. See `tmp/llm-mutation-report.md` for the full report with diffs and verdicts.

See `docs/comparison.md` for a function-by-function comparison of which mutations each tool found
and where they diverge.

**Cost note:** `--generate` mode logs an estimated cost footer (Sonnet 4.6 rates: $3.00/MTok
input, $15.00/MTok output) in the report.

---

## Demo Branches

Two git branches let you switch between the broken and fixed states without editing files:

- `demo/weak-tests` — the green-but-broken state (created in Phase 5 Plan 02)
- `demo/fixed-tests` — boundary tests added; most mutations now killed

```bash
# Switch to the weak-tests state and run the demo
git checkout demo/weak-tests
COVERAGE=1 bundle exec rspec          # 28 tests, 100% coverage, all green
bundle exec rake mutant               # 2.31% kill rate — 253 mutations survive
# /llm-mutate --replay               # 0/20 LLM mutations killed

# Switch to the fixed-tests state and observe mutations killed
git checkout demo/fixed-tests
bundle exec rake mutant               # kill rate climbs significantly
# /llm-mutate --replay               # most mutations now killed

# Return to the development state
git checkout main
```

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
