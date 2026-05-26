---
name: llm-mutate
description: >
  LLM-driven mutation testing skill for Ruby codebases. Generates semantically
  meaningful mutations in the style of Meta's ACH research ("what a careless developer
  would write"), validates each mutation with ruby -c, runs the RSpec suite to classify
  killed vs survived mutations, and writes tmp/llm-mutation-report.md. Invoke as
  /llm-mutate --replay (deterministic demo mode using committed fixture) or
  /llm-mutate --generate (live generation with MAX_MUTATIONS cap, default 20).
disable-model-invocation: false
---

# llm-mutate

LLM-driven mutation testing for `lib/date_utils.rb`. Complements the `mutant` gem baseline
(Act 1) by generating semantically meaningful mutations in the style of Meta's ACH research —
"what a careless developer would write" — rather than exhaustive operator substitutions.

## Invocation

```
/llm-mutate --replay     # Deterministic replay from committed fixture (use for demo)
/llm-mutate --generate   # Live generation — Claude reads lib/ and generates mutations
```

## --replay Mode

Follow these steps exactly when invoked with `--replay`.

**Step 1 — Read the fixture.**
Read the file `.claude/skills/llm-mutate/fixtures/canonical.json`. Parse the `mutations` array.
Record: total mutation count N.

**Step 2 — Prepare workspace.**
Run: `mkdir -p tmp/mutants`
This directory is gitignored. All mutation files are written here.

**Step 3 — Validate all mutations with ruby -c.**
For each mutation in the fixture:
  a. Construct the mutated source by reading `lib/date_utils.rb` and replacing the line that
     exactly matches `original_line` (after stripping leading whitespace) with `mutated_line`
     (with the same leading whitespace as the original). If no line matches, log:
     `SKIP <id>: original_line not found in lib/date_utils.rb` and continue.
  b. Write the mutated source to `tmp/mutants/<id>.rb`.
  c. Run: `ruby -c tmp/mutants/<id>.rb`
     - If exit code is non-zero: log `INVALID <id>: ruby -c failed` and mark as invalid. Do NOT run RSpec.
     - If exit code is 0: continue to Step 4.

Track: invalid_count = number of mutations that failed ruby -c.

**Step 4 — Run the kill detector for each valid mutation.**
For each mutation that passed ruby -c:
  Run: `bash .claude/skills/llm-mutate/scripts/run_mutant_spec.sh tmp/mutants/<id>.rb`
  Capture the exit code.
  - Exit 0: mutation SURVIVED (tests did not catch the change). Record verdict: "survived".
  - Exit non-zero: mutation KILLED (tests caught the change). Record verdict: "killed".

**Step 5 — Render the report.**
Write `tmp/llm-mutation-report.md` with this exact structure:

```
# LLM Mutation Report — Replay Mode

**Fixture:** .claude/skills/llm-mutate/fixtures/canonical.json
**Mode:** --replay (deterministic)
**Total mutations:** {N}
**Invalid (ruby -c rejected):** {invalid_count}
**Killed:** {killed_count}
**Survived:** {survived_count}
**Mutation score:** {killed_count}/{N-invalid_count} ({pct}%)

---

## Per-Function Breakdown

| Function | Total | Killed | Survived |
|----------|-------|--------|----------|
| days_between | {n} | {k} | {s} |
| add_business_days | {n} | {k} | {s} |
| leap_year? | {n} | {k} | {s} |
| age_in_years | {n} | {k} | {s} |
| next_occurrence_of_weekday | {n} | {k} | {s} |
| weeks_between | {n} | {k} | {s} |

---

## Mutation Details

### days_between

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-DB-01 | {description} | SURVIVED / KILLED | yes/no |
...

### add_business_days
...

(repeat for all 6 functions)

---

## Diff — Survived Mutations

For each survived mutation, include:

### {id} — {function}

**Description:** {description}

**Diff:**
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
- {original_line}
+ {mutated_line}

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** {yes/no}

---

## Estimated Cost

Mode: --replay (no LLM calls made during replay)
Fixture generation cost: N/A — fixture is hand-curated (Phase 4 plan 02)
RSpec runs: {N-invalid_count} executions of bundle exec rspec spec/date_utils_spec.rb

*Note: --generate mode logs estimated token cost. --replay mode has no LLM token usage.*
```

Fill in all {placeholders} with actual counts from the run. Do not hardcode numbers — compute
them from the actual run results.

**Step 6 — Print summary to stdout.**
Print:
```
LLM Mutation Report complete.
  Mutations: {N} total, {invalid_count} invalid, {killed_count} killed, {survived_count} survived
  Score: {pct}%
  Report: tmp/llm-mutation-report.md
```

**Determinism guarantee:** The report content is fully determined by the fixture file.
No random elements, no timestamps. Identical fixture → identical report.

---

## --generate Mode

See Plan 04-03 — this section is filled in by the generate implementation.

(Placeholder: when invoked with --generate, Claude generates fresh mutations live.
MAX_MUTATIONS default 20. Writes to tmp/generated/. See full instructions in Plan 03.)

---

## Shared Pipeline Notes

- The kill detector script always restores `lib/date_utils.rb` after each run.
  Multiple mutation runs leave the library in its original state.
- `ruby -c` validation runs BEFORE the RSpec wrapper. Invalid Ruby is discarded silently
  (count logged) and does not appear as a survived or killed mutation.
- All temporary files live under `tmp/` (gitignored). The fixture under `fixtures/` IS committed.
