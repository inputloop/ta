# RISK — canon

> **Author.** Corwin Brust &lt;corwin@bru.st&gt;, 2026. **License.** CC BY 4.0 (docs) /
> GPL-3.0-or-later (code). **Identity.** SHA-256 of its own bytes; sidecar alongside.
> **Status.** v1.0.51 (Q-8 settled 2026-08-29). **Binding** — stated by Corwin 2026-08-28 (anchor A16); the cell
> mechanics below are mine, built to serve it.

## The rule, in his words

> "we do not call it 'risk' unless it is measured. measured purports to be information
> (the word 'risk' once affixed veritably screams 'understand me' to the bearer)"

Two measures, at minimum, or the word is not available:

**OCCR_FCTR — likelihood to occur.** Communicated as a **percentile** by preference.
Calculated per context "to the most comprehensive formula we find salient and can defend
per information based analytical and journalistic ('story telling!' but nominally:)
'evidentiary' style 'receipting'." Detail is not narrated during routine work unless the
detail must be surfaced to describe what changed or what was noticed.

**COST_BLST — material+ costs graph.** A single number, a roll-up, or a fully graphed
cost/impact analysis, considering **at least one materially noticeable expense, fee, or
other material spending — including time, even where time is not otherwise tracked as
cost.** Produces a number, generally in **whole dollars** or **whole dollars per unit**,
and may produce a series at graduating percentages, a series of series, a pie, or
whatever the need calls for.

## The lexical line (mine, following from his rule)

| Word | Requires | May be used in |
|---|---|---|
| **RISK** | OCCR_FCTR **and** COST_BLST, each with a receipt | plans, reports, decisions |
| **CONCERN** | nothing but a name and a reason | anywhere, but never priced |
| **HAZARD** | a named mechanism, no numbers yet | design talk, pre-measurement |

An unmeasured thing is a **CONCERN**. Promoting a CONCERN to a RISK is an act with a
date and a receipt. A missing OCCR_FCTR is **UNMEASURED** — never zero, never "low."
Writing 0 where you mean unknown is the failure this canon exists to stop.

## The cell

The simple cell is one row. Every field is required; `UNMEASURED` is a legal value and
disqualifies the row from the word *risk*.

| field | meaning | form |
|---|---|---|
| `id` | stable handle | short token |
| `name` | what happens | one line, active voice |
| `occr_pct` | OCCR_FCTR | integer 0–100, or `UNMEASURED` |
| `occr_basis` | how that percentile was got | formula/source, one line |
| `cost_usd` | COST_BLST point estimate | whole dollars, or dollars/unit with `cost_unit` |
| `cost_unit` | denominator if per-unit | e.g. `per hour`, `per device`, or `-` |
| `cost_basis` | what the money is | ≥1 materially noticeable expense named |
| `time_hr` | time counted as cost | hours, at `TIME_RATE` |
| `receipt` | where a reader checks both numbers | file, quote, or observation |

**Cell value** = `occr_pct/100 × cost_usd` → **expected cost**, whole dollars.

**The band** (his "series at graduating percentages"): the same cost evaluated at P10 /
P50 / P90 of the occurrence estimate, so the cell reports a range and not a false point.
A cell whose band is wider than its point estimate is telling you the *estimate* is the
problem, not the hazard — that is information, and it is the reason to graph rather than
roll up.

**Roll-up** = sum of expected costs. Roll-up is honest only when the rows are
independent; where they are not, say so in the plan rather than summing quietly.

## Receipting style

Evidentiary, in the journalistic sense he named: a reader must be able to get to the
same number by the route you took. Each basis line answers *what was counted, over what
period, from where.* "Experience suggests" is not a basis; "three of the last five
teardowns, per DRIFT.log entries dated X/Y/Z" is.

**Time is money here by declaration.** `TIME_RATE` is set per context and stated in the
plan that uses it, so that an hour lost is a number and not a shrug. Where no rate is
appropriate, `time_hr` still gets counted and reported separately — never dropped.

## What this canon refuses

- **Colour-only risk.** A red cell that carries no number is a CONCERN wearing a costume.
- **Ordinal arithmetic *as severity*.** "High × Medium" is not a risk. It may not stand
  as `occr_pct` or as `cost_usd`, and `riskcell.sh` refuses it there. **But it is not
  nonsense** — see *The bearing ratio* below: an ordinal product is the bottom rung of
  the **denominator**, where its job is to confess how coarse the instruments are.
  Corrected 2026-08-28; my earlier rule ("if the factors are ordinal, stop") refused the
  whole ladder because of where it starts.
- **Volume as severity.** The count of concerns is not a measure of risk. See
  `MEASURES.md` — this is the volumetric trap in its risk-shaped form.
- **The unmeasured zero.** Absent is `UNMEASURED`, and it is loud.

---

## The bearing ratio — SP / UF

His formula, given 2026-08-28, and the thing the LENS page's fragment was reaching for:

> **SP / UF** — where **UF** is the product of measured **feeling** and **understanding**:
> the "mass weight of total bearing instrumentation, with one end's view simply
> multiplied to make a last-minute volume total approximation. This is a very me
> technique."

### My reading (offered for ratification, not canon)

Mapped onto the LENS figure, the letters fall out of the two bowls:

- **Numerator, the FOCUS side — `S × P`.** What you can **SHOW**, times the
  **PLAN·CONFIDENCE** you hold. This is the size of the claim you are making.
- **Denominator, the UNDERSTANDING side — `U × F`.** **UNDERSTANDING** times **FEEL**
  — the total bearing of your instrumentation, approximated by taking one end's view and
  multiplying it out.

So **SP/UF is a calibration ratio: claim over grounding.**

- **> 1** — you are showing more than you understand. Over-claim. The number the
  epistemic floor exists to catch.
- **≈ 1** — the claim and the grounding are the same size. Where you want to live.
- **< 1** — you understand more than you are showing. Under-claim, or a buried lead —
  which is a real failure here, not modesty.

That last reading is why the ratio is worth having: most calibration tools only catch
over-claim, and this one catches the other direction with the same arithmetic. It is the
lead-with-the-substance clause expressed as a number.

### The rung ladder — where H × M actually sits

`UF` is not one thing; it is whatever resolution your instruments have. **Declare the
rung**, because the ratio is only comparable across items measured on the same one.

| rung | `UF` is | resolution | when it is honest |
|---|---|---|---|
| **0** | an **ordinal product** — H × M and friends | ~3 levels each | when you have judgement and nothing else. It is a **confession**, and confessions compute |
| **1** | **one end's view × extent** — his volume approximation | coarse but numeric | the last-minute total; fast, defensible, and says so |
| **2** | measured feeling × measured understanding, each with its own probe | real units | when the two have been instrumented separately |
| **3** | per-component bearing **summed**, not approximated | full | when the instrumentation exists and the stakes pay for reading it |

The rung is reported with the ratio, always: `SP/UF = 1.4 (rung 1)`. A rung-0 ratio and a
rung-3 ratio are different kinds of statement wearing the same numeral, and comparing
them silently is the failure this column prevents.

### The honest weakness — and it is in the denominator

You said "totally cool if my math isn't," so: **`UF` is gameable by padding.** Its own
description is quantity-flavoured — *mass weight of total bearing instrumentation* — and
a quantity in a denominator makes the ratio fall when you add instruments without
understanding more. Run our own Probe A on it: volume up, value flat → `UF` rises →
`SP/UF` falls → the tool reports *less over-claim* for having bought more gauges. That is
Probe A failing, in the one place we would not have looked.

Two ways out, and they are different in kind:

1. **Fence it, as we fence tokens.** A volumetric denominator is legitimate *as a
   denominator* — that is exactly what the measures canon says volume is good for. Then
   the rule is: `UF` may never be improved by adding instrumentation inside a single
   comparison. Cheap, and it keeps the technique intact.
2. **Make the cross-section carry understanding, not count.** "One end's view" is doing
   real work here: if the face you multiply out is *how much of the bearing you can
   actually read from one end* — comprehension, not inventory — then padding does not
   raise it, and the approximation is sound. This is my preferred reading, and it may be
   what you meant all along.

**Q-8 ANSWERED by Corwin 2026-08-29: a READ.** "One end's view" is *how much of the
bearing you can actually take in*, not an inventory of what is deployed. **Way 2 governs;
way 1 is not needed.**

**The padding exposure CLOSES**, and it closes properly rather than by fiat: buying more
gauges does not raise a *read*, because comprehension is not inventory. Run Probe A on the
settled definition — volume up (more instruments), value flat (no more understood) → `UF`
unchanged → `SP/UF` unchanged. **It passes.** The one place we would not have looked turns
out to be sound, and it is sound because of what the word already meant.

Two things follow and both are mechanical:

- **`face_kind` keeps its teeth.** A row declaring `count` still earns
  `[padding exposure LIVE]` from `bin/bearing.sh`, and that is now a statement about *that
  row's instrument*, not a doubt about the formula. `B-SURFACE` is the live example: an
  inventory of what fits on the bench, honestly declared, honestly flagged.
- **The default is `read`**, and a row that cannot say how much of its bearing is legible
  from one end should say `count` and take the flag rather than round up.

### What it is for

The ratio does not price a hazard; that is the cell's job. **SP/UF prices the claim** —
and so it belongs at beat 3 of the loop, where a guess is settled: report the delta, and
report the ratio, and the pair says both *how wrong you were* and *how entitled you were
to be that confident.*

## Tools

- `bin/riskcell.sh` — reads a risk TSV, validates the fields, computes expected cost and
  the P10/P50/P90 band, emits the roll-up and a receipt block. Refuses to print the word
  *risk* over any row that is UNMEASURED.
- `bin/selftest.sh` — includes the negative controls: a row with `occr_pct=UNMEASURED`
  must be refused; an ordinal cost must be refused; a cell with no receipt must be
  refused. A checker that cannot fail is not a checker.

## Provenance note — settled

**Resolved 2026-08-28, by him:** the "simple cell" was just that — *a single field called
`risk`*, the one-cell representation the register used before this canon. Not an earlier
model of mine to recover. So the multi-field row above is the elaboration of that one
cell into the fields that make the word earnable, and the `UNMEASURED` value is what the
empty single cell should have been saying all along.

My previous note here guessed that he meant a model I had presented and could not find.
He meant something simpler. Recorded rather than deleted, because the wrong guess is the
kind of thing this project keeps.

---

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
