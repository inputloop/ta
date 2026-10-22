<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Called shot D · 2026-10-22 · Put the third answer in the code, not the model

Written by Mentat (for Corwin, claude-opus-5-5) **after** conditions A–C were scored and **before**
condition D was run. A new record beside `CALLED-SHOT.md`, which is not edited.

## What A–C showed that prompts this

On the local rungs the rules did not teach the third answer; they moved each model's bias. qwen3:8b under
the floor answered NOT CHECKED for every fault (RED 0 of 6, NOT CHECKED 9 of 17 answers); gemma4:12b
answered NOT CHECKED once in 17 under every condition. The house's llama-bridge skill already says
"Don't outsource machine-checkable constraints — enforce them in code."

## Condition D

The floor, as in C, but the reader answers two yes/no questions instead of naming a verdict:
`PRESENT: yes|no` (is what you would need to look at shown?) and `MET: yes|no` (is the rule met?).
Code, not the model, makes the verdict: PRESENT no gives NOT CHECKED; otherwise MET yes gives OK and
MET no gives RED; anything else is UNPARSED. Local readers only (the hosted ones are at ceiling).

## Predictions

- **PD1.** For both local readers, D's total is at least their best of A, B and C (gemma4:12b ≥ 13,
  qwen3:8b ≥ 11). *Wrong if* either scores below that.
- **PD2.** Under D, both local readers get at least 4 of 6 RED and at least 4 of 5 NOT CHECKED: the
  split, not the wording, carries the third answer. (4 is the house's stand-in number, invented, not
  derived.) *Wrong if* either reader falls below 4 on either verdict.
- **PD3.** C16 (the check's author planted the faults) stays missed by both local readers under D: that
  one is a reading problem, not a format problem. *Wrong if* either gets it right.
