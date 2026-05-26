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
  a. Construct the mutated source by reading `lib/date_utils.rb` and replacing the FIRST line
     whose stripped content exactly matches `original_line` with `mutated_line` (preserving
     the same leading whitespace as the original). If the line appears more than once, only
     replace the first occurrence and log a WARNING. If no line matches, log:
     `SKIP <id>: original_line not found in lib/date_utils.rb` and continue.
  b. Write the mutated source to `tmp/mutants/<id>.rb`.
  c. Run: `ruby -c tmp/mutants/<id>.rb`
     - If exit code is non-zero: log `INVALID <id>: ruby -c failed` and mark as invalid. Do NOT run RSpec.
     - If exit code is 0: continue to Step 4.

Track: invalid_count = number of mutations that failed ruby -c.
       skip_count = number of mutations whose original_line was not found in the source.

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
**Skipped (original_line not found):** {skip_count}
**Invalid (ruby -c rejected):** {invalid_count}
**Killed:** {killed_count}
**Survived:** {survived_count}
**Mutation score:** {killed_count}/{N-invalid_count-skip_count} ({pct}%)

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
RSpec runs: {N-invalid_count-skip_count} executions of bundle exec rspec spec/date_utils_spec.rb

*Note: --generate mode logs estimated token cost. --replay mode has no LLM token usage.*
```

Fill in all {placeholders} with actual counts from the run. Do not hardcode numbers — compute
them from the actual run results.

**Step 6 — Print summary to stdout.**
Print:
```
LLM Mutation Report complete.
  Mutations: {N} total, {skip_count} skipped, {invalid_count} invalid, {killed_count} killed, {survived_count} survived
  Score: {pct}%
  Report: tmp/llm-mutation-report.md
```

**Determinism guarantee:** The report content is fully determined by the fixture file.
No random elements, no timestamps. Identical fixture → identical report.

---

## --generate Mode

Follow these steps exactly when invoked with `--generate`.

**Step 1 — Read the library.**
Read `lib/date_utils.rb` in full. Identify all six public functions:
`days_between`, `add_business_days`, `leap_year?`, `age_in_years`,
`next_occurrence_of_weekday`, `weeks_between`.

For each function, note:
- The branching conditions (if/unless/while/each)
- Any arithmetic operations
- Any comparison operators
- Boundary conditions documented in comments (look for "Intentional bug:" annotations)

**Step 2 — Prepare workspace.**
Run: `mkdir -p tmp/generated`
This directory is gitignored. All generated mutation files are written here.

**Step 3 — Set the budget.**
MAX_MUTATIONS = 20 (default). Distribute across 6 functions: target 3-4 mutations per function,
stopping globally when the total reaches MAX_MUTATIONS. Do not exceed this cap regardless of
how many functions remain. Log the distribution plan before generating.

**Step 4 — Generate mutations using Meta ACH style.**
For each function (in order: days_between, add_business_days, leap_year?, age_in_years,
next_occurrence_of_weekday, weeks_between), generate mutations up to budget:

  Generate each mutation as follows:
  a. Ask yourself: "What would a careless developer write here?" Focus on:
     - Off-by-one errors (< vs <=, +1 vs -1)
     - Missing edge-case handling (skipping a guard clause)
     - Wrong operator (+ instead of -, / instead of *)
     - Incorrect method (wrong String/Integer method that almost works)
     - Semantically plausible but wrong boundary (% 8 instead of % 7)
  b. Express the mutation as a single-line change: one original_line (exact text from lib/)
     and one mutated_line (the replacement). Multi-line mutations are not supported.
  c. Write a plain-English description in the form: "A careless developer [action] — this causes
     [effect] when [condition], but no test exercises this path so it goes undetected."
  d. Assign a stable ID using scheme LM-{ABBREV}-G{NN} where ABBREV is the function abbreviation
     and NN is a two-digit counter (G prefix means generated, not from fixture).

**Step 5 — Validate with ruby -c.**
For each generated mutation:
  a. Construct the mutated source by reading `lib/date_utils.rb` and replacing the FIRST line
     whose stripped content exactly matches original_line with mutated_line (same leading whitespace).
     If the line appears more than once, only replace the first occurrence and log a WARNING.
  b. Write the mutated source to `tmp/generated/<id>.rb`.
  c. Run: `ruby -c tmp/generated/<id>.rb`
     - Exit non-zero: log `INVALID <id>: rejected by ruby -c`. Increment invalid_count.
       Do NOT run RSpec for this mutation.
     - Exit 0: proceed to Step 6.

Track: invalid_count, generated_count (attempted), valid_count (passed ruby -c).

**Step 6 — Run the kill detector.**
For each mutation that passed ruby -c:
  Run: `bash .claude/skills/llm-mutate/scripts/run_mutant_spec.sh tmp/generated/<id>.rb`
  - Exit 0: mutation SURVIVED.
  - Exit non-zero: mutation KILLED.
  Record verdict.

**Step 7 — Render the report.**
Write `tmp/llm-mutation-report.md` using the same format as --replay mode, with these differences:

  - Header: `# LLM Mutation Report — Generate Mode`
  - Source line: `**Source:** Generated live in current Claude Code session`
  - Mode line: `**Mode:** --generate (live LLM generation)`
  - Sections for only the generated mutations (not fixture mutations)
  - Include the estimated cost footer (see below)

**Step 8 — Estimated cost footer.**
Append this section to `tmp/llm-mutation-report.md`:

```
---

## Estimated Cost

**Model:** claude-sonnet-4-6 (session model)
**Pricing:** $3.00/MTok input, $15.00/MTok output

Estimate method: character count ÷ 4 ≈ tokens (rough approximation).
Actual token usage is not accessible from within a Claude Code skill.

| Item | Approx chars | Approx tokens | Rate | Estimated cost |
|------|-------------|---------------|------|----------------|
| Library read (input) | ~2,200 | ~550 | $3/MTok | ~$0.0000017 |
| Mutation generation prompts (input) | ~{gen_count * 500} | ~{gen_count * 125} | $3/MTok | ~${input_cost:.7f} |
| Generated mutation text (output) | ~{gen_count * 300} | ~{gen_count * 75} | $15/MTok | ~${output_cost:.7f} |
| **Total estimated** | | | | **~${total_cost:.6f}** |

*Labeled "estimated" — actual billing may differ. This is an order-of-magnitude guide.*
*For {gen_count} mutations at claude-sonnet-4-6 rates, expect < $0.01 per run.*
```

Fill in the table using these formulas:
  input_chars = gen_count * 500     (approximate per-mutation prompt size)
  output_chars = gen_count * 300    (approximate per-mutation output size)
  input_tokens = input_chars / 4
  output_tokens = output_chars / 4
  input_cost = (input_tokens / 1_000_000.0) * 3.0
  output_cost = (output_tokens / 1_000_000.0) * 15.0
  total_cost = input_cost + output_cost + 0.0000017  (add the library read cost)

Format all cost values as 7 decimal places (e.g., $0.0000019).

**Step 9 — Print summary.**
Print:
```
LLM Mutation Report complete (--generate mode).
  Generated: {gen_count} mutations attempted, {invalid_count} rejected by ruby -c
  Valid mutations run: {valid_count}
  Killed: {killed_count} | Survived: {survived_count}
  Score: {killed_count}/{valid_count} ({pct}%)
  Estimated cost: ~${total_cost:.6f}
  Report: tmp/llm-mutation-report.md
```

---

## Shared Pipeline Notes

- The kill detector script always restores `lib/date_utils.rb` after each run.
  Multiple mutation runs leave the library in its original state.
- `ruby -c` validation runs BEFORE the RSpec wrapper. Invalid Ruby is discarded silently
  (count logged) and does not appear as a survived or killed mutation.
- The kill detector stores its restore backup at `.claude/skills/llm-mutate/tmp/date_utils.orig.rb`
  (gitignored). Mutation files written by the skill live under `tmp/mutants/` (--replay) or
  `tmp/generated/` (--generate), also gitignored. The fixture under `fixtures/` IS committed.
