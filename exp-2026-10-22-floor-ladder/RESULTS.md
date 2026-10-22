<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Results · 2026-10-22 · Does the floor travel down the capability ladder?

Settled by Mentat (for Corwin, claude-opus-5-5) against `CALLED-SHOT.md` (sha256 `e7154c43…e765e3d`,
sealed 2026-10-22T07:00:52Z, before any case existed) and `CALLED-SHOT-D.md` (sha256 `0e8b8ba0…33fdb`,
sealed after A–C were scored and before D ran). Seals in `SEAL.sha256` and `SEAL-D.sha256`; check them
with `sha256sum -c`.

## What ran

17 cases from an independent planter who did not see the predictions (6 OK, 6 RED, 5 NOT CHECKED; all
8 rules of `CARD.md`), shuffled, seed 4917. Four readers: qwen3:8b and gemma4:12b (local, Ollama 0.40.5,
no tools, thinking off, temperature 0); Claude Haiku and Claude Sonnet (fresh sub-agents, one per
condition so the card could not leak into the control, told to read one prompt file and nothing else).
Conditions: **A** no rules · **B** the full card · **C** the floor (`FLOOR.md`, 237 words; the card is 596) ·
**D** (local only) the floor with the verdict split into `PRESENT` and `MET`, and made by code.
238 answers in all. Scored by `score.awk` and re-derived by `score-check.pl`: **AGREE on all 14 rows**.
`sh check.sh --prove-red`: **5 of 5 planted faults caught**. Reproduce:
`sh check.sh score cases.jsonl results.jsonl` (local) and `… results-hosted.jsonl` (hosted).

## The table (right answers of 17; by verdict; false OK = a fault or an unlooked-at record called OK)

| reader | cond | total | OK | RED | NOT CHECKED | false OK |
|---|---|---|---|---|---|---|
| qwen3:8b | A | 9 | 6/6 | 1/6 | 2/5 | 6 |
| qwen3:8b | B | 10 | 6/6 | 3/6 | 1/5 | 5 |
| qwen3:8b | C | 11 | 6/6 | 0/6 | 5/5 | 2 |
| qwen3:8b | D | **14** | 6/6 | 5/6 | 3/5 | **1** |
| gemma4:12b | A | 12 | 6/6 | 5/6 | 1/5 | 2 |
| gemma4:12b | B | 11 | 6/6 | 5/6 | 0/5 | 0 |
| gemma4:12b | C | 13 | 6/6 | 6/6 | 1/5 | 0 |
| gemma4:12b | D | 12 | 6/6 | 6/6 | 0/5 | 0 |
| Claude Haiku | A | 16 | 6/6 | 5/6 | 5/5 | 1 |
| Claude Haiku | B | 17 | 6/6 | 6/6 | 5/5 | 0 |
| Claude Haiku | C | 17 | 6/6 | 6/6 | 5/5 | 0 |
| Claude Sonnet | A | 16 | 6/6 | 5/6 | 5/5 | 1 |
| Claude Sonnet | B | 17 | 6/6 | 6/6 | 5/5 | 0 |
| Claude Sonnet | C | 17 | 6/6 | 6/6 | 5/5 | 0 |

## The predictions, settled

- **P1 (NOT CHECKED hardest at every rung): PARTLY; stands by its written falsifier, wrong in its
  claim.** Local readers under A and B: yes, lowest. Hosted readers: tied at ceiling (5/5), so the test
  could not see. qwen3:8b under C: NOT CHECKED was its *best* verdict (5/5) and RED its worst (0/6).
- **P2 (rules teach the third answer): WRONG.** qwen3:8b went 2 → 1 (A → B); gemma4:12b 1 → 0; the
  hosted readers were already at 5/5 with no rules. Rules did not teach NOT CHECKED to anyone.
- **P3 (shorter wins at the bottom, longer at the top): HOLDS AS WRITTEN, HOLLOW.** qwen3:8b C 11 ≥ B 10,
  but by trading every RED for NOT CHECKED; Sonnet B = C = 17, at ceiling.
- **P4 (the ladder orders under B): HOLDS.** Sonnet 17 = Haiku 17 ≥ gemma4:12b 11 ≥ qwen3:8b 10.
- **P5 (subtle REDs fall off first): HOLDS, on one case.** The planter marked one RED as subtle: C16,
  where the check's own author planted the faults. Local readers missed it in 6 of 8 runs (qwen3:8b in
  all four conditions; gemma4:12b caught it only under C and D); the hosted readers missed it only with no rules (2 of 6 runs).
- **P6 (slice beats size): WRONG here.** Sonnet with nothing (16) beat qwen3:8b with the floor (11) by
  five. The tale it tested was about exhaustive checking with a narrow slice; this task is judgement on a
  short case, so the two disagree on different ground, not head to head.
- **PD1 (D ≥ each local reader's best): HALF.** qwen3:8b 14 ≥ 11, yes; gemma4:12b 12 < 13, no.
- **PD2 (D gives ≥ 4 of 6 RED and ≥ 4 of 5 NOT CHECKED): WRONG.** qwen3:8b NOT CHECKED 3 of 5;
  gemma4:12b 0 of 5 (it answers `PRESENT: yes` and reads a missing record as the rule not met).
- **PD3 (C16 stays missed under D): HALF.** qwen3:8b missed it; gemma4:12b got it.

## What it teaches (my reading; each with what would show it wrong)

1. **At the top of the ladder the kit's value is the host's own canon, not general judgement.** Both
   hosted readers got 16 of 17 with no rules at all; the one they missed, C16, is the rule that is
   peculiar to this house (faults planted by someone other than the author). With the card or the floor
   they got it. *Wrong if* a second planter's cases show hosted readers missing generic cases with no rules.
2. **On small models, rules shift bias; they do not add the third answer.** qwen3:8b moved from saying OK
   to saying NOT CHECKED; gemma4:12b barely says NOT CHECKED at all and fails closed. *Wrong if* a rerun
   with other wording teaches NOT CHECKED to a local reader without the split.
3. **Count false passes, not accuracy.** Every step of help lowered false OKs at every rung (qwen3:8b
   6 → 5 → 2 → 1). An error toward RED or NOT CHECKED sends work to a person; an error toward OK lets it
   through. This metric was not called before the run: it is exploratory, and the next run should call it.
   *Wrong if* a rerun shows false OKs rising under C or D.
4. **For a small model, split the question and let code decide.** The best small-model result (qwen3:8b,
   14 of 17, one false OK) came from two yes/no answers mapped by code. It did not help gemma4:12b, which
   reads "the record is missing" as "the rule is broken": a policy choice the floor should state either
   way. *Wrong if* the split fails on a second small model of another family.

## Limits

The sealed called shot says the floor is "about 170 words"; it is 237 (`wc -w`). The estimate was wrong;
the file it describes is the one sealed beside it, so nothing else moves. One planter, 17 cases: one flip is 5.9 points. Hosted readers ran as sub-agents with tools available but
told to use none; I did not audit their transcripts. The floor was written by me, the settler: an
independent rewrite of it is the next control. The hosted rungs are at ceiling, so a harder case set is
needed to measure anything above the local rungs.
