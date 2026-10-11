# MEASURES — measure-tags, semantic tags, and the volumetric guard

> **Author.** Corwin Brust &lt;corwin@bru.st&gt;, 2026. **License.** CC BY 4.0 (docs) /
> GPL-3.0-or-later (code). **Status.** v1.0.50. The requirement is his (2026-08-28,
> anchor A17): *measures, tags, and measure-tags-that-are-not-semantic-tags, balanced so
> we hold proofs that our measures are NOT volumetric and do not fall back to something
> volumetric.* The construction below is mine.

## The failure this exists to stop

A **volumetric** measure is one whose value rises with the *quantity* of what was
produced or consumed, independently of whether the work got better. Tokens, bytes,
lines, files, turns, commits, page count. They are seductive because they are free to
collect and always available — so an unguarded metric suite converges on them, and
"we did a lot" quietly becomes "we did well."

Worse is the **fallback**: a measure that looks semantic but is computed from a
volumetric proxy underneath — "coverage" that counts assertions, "thoroughness" that
counts sections, "effort" that counts time-on-task. It passes inspection and fails the
guard.

The kit already holds the doctrine — *account to value by deference, not by metric* —
but doctrine is not a check. This is the check.

## Two tag kinds, and the wall between them

**SEMANTIC tags** say what a thing is *about*. `teardown`, `delicate`, `empyrean`,
`front-door`. They are for finding things, grouping things, and talking. They are
authored by people and may be argued about.

**MEASURE tags** say how a number was *obtained* and what it may be compared to. They
are metadata on a measurement, not on a subject.

| measure-tag | values | what it fixes |
|---|---|---|
| `unit` | `usd`, `hour`, `pct`, `count`, `ratio` | what the number is |
| `denom` | the per-what, or `-` | stops per-unit numbers being summed as totals |
| `dir` | `up-good`, `down-good` | stops sign confusion in roll-ups |
| `vol` | `volumetric`, `non-volumetric`, `derived` | the guard's subject |
| `basis` | `counted`, `estimated`, `guessed`, `receipted` | how much weight it bears |
| `fresh` | ISO date the value was taken | stops stale numbers reading as current |

**The wall, and it is the load-bearing rule:**

1. **A semantic tag may never enter a computation.** The moment `delicate` becomes a
   multiplier, an argument about meaning has been laundered into arithmetic.
2. **A measure tag may never be used for retrieval or meaning.** You do not search for
   things tagged `up-good`; you do not conclude anything from a thing being `pct`.
3. **A measure carries both kinds and mixes neither.** The subject is tagged
   semantically; the number is tagged measurally; they meet in a row, never in a
   formula.

Where the two are allowed to touch: a semantic tag may **select which rows** are
measured, and may **be reported alongside** the number. That is deference — the
semantics decide what matters, the measures say how much, and the operator owns the
join.

## The guard — a proof-pair per measure

Every declared measure ships two synthetic probes. Both must pass or the measure is not
admissible.

**Probe A — VOLUME-UP, VALUE-FLAT (the negative control).**
Double the volume of the artifact or the run without improving the outcome. The measure
**must not** rise materially (tolerance declared per measure; default ≤5%).
*If it rises, the measure is volumetric.* FAIL.

**Probe B — VOLUME-FLAT, VALUE-UP (the positive probe).**
Improve the outcome — a caught error, a settled guess, a shorter path to the same
result — without changing volume. The measure **must** rise (or fall, per `dir`).
*If it does not move, the measure is insensitive and is measuring nothing you care
about.* FAIL.

A measure that passes A but fails B is the commonest and most flattering failure: it is
stable, it is defensible, and it is inert. Report it as FAIL, not as "conservative."

**Fallback detection.** A measure tagged `derived` must name its inputs. If the
transitive closure of its inputs contains only `volumetric` leaves, the measure is
volumetric no matter how semantic its name — the tool computes this closure rather than
trusting the label.

## The measures this project declares

Declared in `measures.tsv`; each row carries its probes and its last guard result.

| measure | what it is | why non-volumetric |
|---|---|---|
| `guess_delta` | absolute difference between the beat-1 guess and the settled actual, per loop | doubling output cannot improve it; only a better guess can. Falls as calibration improves (`dir=down-good`) |
| `guess_calib` | share of guesses whose actual landed inside the stated band | pure ratio over guesses made; adding work adds denominator too |
| `first_pass_exit` | share of loops that met exit criteria without a second try | volume-up typically *hurts* it |
| `refusal_rate` | share of runs where a checker correctly refused | a checker that never fails scores zero; cannot be inflated by output |
| `receipt_reach` | share of load-bearing claims a stranger can re-derive from the cited receipt | adding unreceipted prose lowers it |
| `risk_priced` | share of named CONCERNs promoted to RISK with both factors and a receipt | naming more concerns lowers it until they are priced |
| `tokens`, `wallclock` | **declared volumetric on purpose** | kept as *cost* inputs only; barred by the tool from ever appearing as a value or quality measure |

The last row is the honest part: the loop page names Tokens and Time as measures, and
they are — of **cost**. They are admitted with `vol=volumetric` and fenced: `riskcell`
and the report will use them as denominators and expenses, and refuse them as evidence
of quality. Fencing them beats pretending we do not use them.

## Why "MORE, ACCURATE, FASTER each time" needs this

His own success criterion is three measures, and exactly one of them is safe:

- **MORE** — volumetric by construction. Rewritten as `first_pass_exit` and
  `receipt_reach`: *more settled, not more produced.*
- **ACCURATE** — `guess_delta` and `guess_calib`. Safe, and the best of the three,
  because accuracy of a *guess* cannot be manufactured by volume.
- **FASTER** — `wallclock` is volumetric-adjacent and gameable by doing less. Fenced as
  cost, and paired: faster only counts when `first_pass_exit` holds.

## Tools

- `bin/measure-guard.sh` — runs Probe A and Probe B per declared measure, computes the
  derived-input closure, prints PASS/FAIL with the numbers. Exits non-zero on any FAIL.
- `bin/selftest.sh` — runs the guard against **two planted measures**: one honestly
  volumetric (`bytes_written`) that must FAIL Probe A, and one inert
  (`constant_seven`) that must FAIL Probe B. If either planted failure passes, the
  guard itself is broken and the selftest says so.

---

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
