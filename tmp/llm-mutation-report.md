# LLM Mutation Report — Generate Mode (Fixed Library)

**Source:** Generated for demo/fixed-tests branch — fixed library with boundary tests
**Mode:** --generate (boundary-targeted mutations for fixed lib/date_utils.rb)
**Total mutations:** 13
**Invalid (ruby -c rejected):** 0
**Killed:** 13
**Survived:** 0
**Mutation score:** 13/13 (100.0%)

---

## Per-Function Breakdown

| Function | Total | Killed | Survived |
|----------|-------|--------|----------|
| days_between | 3 | 3 | 0 |
| add_business_days | 1 | 1 | 0 |
| leap_year? | 3 | 3 | 0 |
| age_in_years | 3 | 3 | 0 |
| next_occurrence_of_weekday | 2 | 2 | 0 |
| weeks_between | 1 | 1 | 0 |

---

## Mutation Details

### days_between

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-DB-G01 | A careless developer drops .abs — reversed date inputs return negative counts, but no test exercises reversed order so it goes undetected. | KILLED | yes |
| LM-DB-G02 | A careless developer uses `start_date - end_date` (wrong operand order without abs) — reversed dates return negative values, exposing the semantic gap. | KILLED | yes |
| LM-DB-G03 | A careless developer calls `.abs` on `start_date` instead of the result — `start_date.abs` is not a valid Date operation and breaks the method entirely. | KILLED | yes |

### add_business_days

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-AB-G01 | A careless developer removes the weekend guard in the step counter — `steps += 1` always increments, counting weekend days as business days. The boundary test for Saturday-start with n=-1 exposes this. | KILLED | yes |

### leap_year?

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-LY-G01 | A careless developer drops the 400-year exception entirely — restoring the original bug where year 2000 returns false. The `leap_year?(2000)` test now catches this. | KILLED | yes |
| LM-LY-G02 | A careless developer uses 300 as the 400-year divisor — `year % 300` is wrong and makes year 2000 incorrectly fail the exception check. | KILLED | yes |
| LM-LY-G03 | A careless developer flips the 400-year logic — changes `!(year % 400).zero?` to `(year % 400).zero?`, making the guard fire for multiples of 400 instead of non-multiples. | KILLED | yes |

### age_in_years

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-AI-G01 | A careless developer removes Feb-29 normalization entirely — `bday = birthdate.day` without clamping means Feb 29 birthdays in non-leap years get an extra year subtracted. | KILLED | yes |
| LM-AI-G02 | A careless developer uses `birthdate.day` directly in the comparison instead of the normalized `bday` — same effect as LM-AI-G01, demonstrating that bypassing the fix variable is equivalent. | KILLED | yes |
| LM-AI-G03 | A careless developer sets the clamp value to 29 instead of 28 — `? 29 : birthdate.day` fails to normalize Feb 29 to a valid non-leap date. | KILLED | yes |

### next_occurrence_of_weekday

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-NO-G01 | A careless developer removes the same-day guard entirely — `days_ahead = 7 if days_ahead.zero?` is dropped, so same-day inputs return 0 days ahead (the input date itself). | KILLED | yes |
| LM-NO-G02 | A careless developer changes the same-day guard to `days_ahead = 0` — the assignment is a no-op (days_ahead is already 0), so same-day inputs still return the same date. | KILLED | yes |

### weeks_between

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-WB-G01 | A careless developer removes .abs from days_between (which also breaks weeks_between for reversed dates) — reversed date inputs produce negative week counts. | KILLED | yes |

---

## Survived Mutations

None. All 13 generated mutations were killed by the boundary-augmented test suite.

---

## Comparison to demo/weak-tests Baseline

| Branch | Mode | Mutations | Killed | Score |
|--------|------|-----------|--------|-------|
| demo/weak-tests | --replay (canonical fixture) | 20 total, 0 invalid | 0 | 0/20 (0.0%) |
| demo/fixed-tests | --generate (boundary-targeted) | 13 generated | 13 | 13/13 (100.0%) |

The boundary tests added to spec/date_utils_spec.rb kill every semantically meaningful mutation
targeting the six fixed boundary conditions. This is the demo's proof-of-concept: writing tests
that exercise boundary cases — not just happy paths — is sufficient to kill LLM-driven mutations
that model exactly the class of bug a careless developer would introduce.

---

## Estimated Cost

**Model:** claude-sonnet-4-6 (session model)
**Pricing:** $3.00/MTok input, $15.00/MTok output

Estimate method: character count ÷ 4 ≈ tokens (rough approximation).

| Item | Approx chars | Approx tokens | Rate | Estimated cost |
|------|-------------|---------------|------|----------------|
| Library read (input) | ~2,200 | ~550 | $3/MTok | ~$0.0000017 |
| Mutation generation prompts (input) | ~6,500 | ~1,625 | $3/MTok | ~$0.0000049 |
| Generated mutation text (output) | ~3,900 | ~975 | $15/MTok | ~$0.0000146 |
| **Total estimated** | | | | **~$0.0000212** |

*Labeled "estimated" — actual billing may differ. This is an order-of-magnitude guide.*
*For 13 mutations at claude-sonnet-4-6 rates, expect < $0.01 per run.*
