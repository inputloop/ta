<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Called shot · 2026-10-22 · Does the floor travel down the capability ladder?

Written by Mentat (for Corwin, claude-opus-5-5) **before** the test cases existed and before any run.
Sealed by the SHA-256 of this file, recorded in `RESULTS.md` beside the settlement. Not edited after the
seal; a correction is a new record.

## The question

The organization-centric offering promises a small floor that "renders everywhere" (OFFERING-2026-09-30
§4, item 4). Everywhere includes weak readers: a small local model with no tools, a chat with no files.
Does a rules card actually let such a reader judge AI-assisted work correctly, and does a shorter
**floor** do better or worse than the full card as the reader gets weaker?

## Design (fixed before cases)

- **Cases:** 17 short scenarios, each judged under one named rule of `CARD-2026-09-30-plain-rules-for-ai-help.md`,
  each with one right verdict: OK, RED, or NOT CHECKED. Written by an independent planter who has not seen
  this file (the ERR-001 lesson: authors' own plants overstate a check).
- **Conditions:** A, no rules (control: the scenario and the three answers only); B, the full card as
  the system prompt; C, the floor (`FLOOR.md`, written here before the cases, about 170 words).
- **Readers (the ladder):** qwen3:8b and gemma4:12b, local, no tools, thinking off, temperature 0;
  Claude Haiku and Claude Sonnet as fresh sub-agents told to answer from the text alone. I am not a
  reader: I wrote the floor.
- **Score:** the first line of the answer, read as OK / RED / NOT CHECKED; anything else is UNPARSED and
  counts wrong. Scored by `score.awk`; re-derived by `score-check.pl`, a second language, which must AGREE.

## Predictions (each with what would show it wrong)

- **P1. NOT CHECKED is the hardest verdict at every rung.** Under every condition, each reader's accuracy
  on the NOT CHECKED cases is its lowest of the three verdicts. *Wrong if* any reader scores NOT CHECKED
  strictly above both OK and RED under condition B.
- **P2. Rules teach the third answer.** For every reader, NOT CHECKED accuracy under B and under C is
  higher than under A. *Wrong if* any reader does as well or better on NOT CHECKED with no rules.
- **P3. Shorter wins at the bottom, longer at the top.** On qwen3:8b, total accuracy C ≥ B. On Sonnet,
  B ≥ C. *Wrong if* either inequality fails.
- **P4. The ladder orders.** Under B: Sonnet ≥ Haiku ≥ gemma4:12b ≥ qwen3:8b in total accuracy.
  *Wrong if* any adjacent pair inverts by more than one case (one case is noise at n = 17).
- **P5. Subtle REDs fall off first.** Cases the planter marks subtle (a one-word quote change and the
  like) are missed by the local models more often than by the hosted ones. *Wrong if* the local models
  catch the subtle REDs at the same rate or better. (Settled only if the planter's `why` lets me name
  which REDs are subtle; otherwise NOT CHECKED.)

- **P6. Slice beats size (graders-tales 008, put to a test).** That tale's reading: "What mattered was
  how much each reader was shown, not how large it was." If it holds here, the smallest reader given the
  floor (qwen3:8b under C) scores at least as well in total as the largest reader given nothing
  (Sonnet under A). *Wrong if* Sonnet under A beats qwen3:8b under C by more than one case. Added before
  the cases existed, after the survey surfaced the tale; the order of writing is said so it can be weighed.

No numeric threshold is invented here beyond "one case is noise": with 17 cases, a single flip is
5.9 points, so the ordering claims are stated as counts, not percentages.

## What this does and does not test

It tests whether a reader can **apply** a rule to a described record. It does not test whether the reader
**keeps** the record, notices a missing rule unprompted, or behaves this way across a long session. One
planter, one family of plants: a second planter is the next step if the result matters.
