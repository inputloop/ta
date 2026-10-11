# Project memory — Technology Architecture

**Updated:** 2026-08-28 · **Working version: 1.0.50** (Emacs scheme — three parts means
working, two means released; next is either `1.1.90` as a delta back to 1.0-based models,
or `2.0` via `2.0.60`/`2.0.90`, and which is not yet knowable.)

## Current state
This folder is the **hub of pointers**. It holds the ledger, the canon, and the tools —
not the shipped models.

**Canon added 2026-08-28:** `RISK-CANON.md` (nothing is *risk* without OCCR_FCTR and
COST_BLST plus a receipt) and `MEASURES.md` (measure-tags walled off from semantic tags;
every measure ships a two-probe non-volumetric proof). Both are tooled, and the tools are
proven able to refuse: `bin/riskcell.sh`, `bin/measure-guard.sh`, `bin/selftest.sh` (8/8,
with three planted measure failures and four planted risk failures).

**Models at 1.0.50:** `operating-model-BASE.md` (the coherent present base — loop, lens,
measures, risk, grounding, identity) and `operating-model-CORWIN-ORG.md` (this project's
own model, with Corwin as the org).

**Worked example:** `LAB-TEARDOWN-plan.md` runs the actual lab teardown through the
method — guesses recorded before the try, five risks priced, two concerns refused.

**Capture:** `NOTES-2026-08-28-lens-and-loop.md` holds both photographed pages verbatim,
with my readings marked as mine and seven read-backs unanswered.

- `COMMENT-ANCHORS.md` — Corwin's comments traced to the work each authorized and the
  file that carries it. Newest comment governs; the older stays as record; nothing
  signed is rewritten (his standing law, anchor A5).
- `DRIFT.log` — hub checkpoints, one line each.
- Three instances, each authoritative for itself: **t0** the kit factory (v1.0, signed
  and tagged, identity `d0843f81…c787a7d`); **t1** the FSF/GNU localization (BASELINE
  from v0.9, SEED v0.4, sidecar-only by design); **t2** Beyond Conventions (org is
  canonical, md/csv are build outputs).
- The `operating-model*.md` files here are the **2026-08-22 origin copies**, superseded
  by the t0 kit. Kept for lineage.

## License — settled 2026-08-28
Documentation and prose **CC BY 4.0**; source code **GPL-3.0-or-later**; attribution to
Corwin Brust &lt;corwin@bru.st&gt;. This supersedes the earlier "unset by design." The
Bryant Frankford / B.K. Graphics credit line rides with the CC BY line and is not to be
dropped when a file is restamped. The Empyrean additional grant lives in the t0 kit's
`LICENSE.md` and is scoped to the named digest.

## What DID improve (the advancement to carry forward)
The model stopped asserting its own trustworthiness and started shipping **checkable
pairs** — a behavior plus the falsifier whose contrapositive is the failure it prevents.
v0.9 split disclosure into share vs record and killed the silent drop; 1.0 added the
provenance anchor and lead-with-framing and killed the stall and the buried lead. Full
table in `COMMENT-ANCHORS.md`.

## Open, and whose
- **The method's name** — my coinage `Called Shot` is offered (alternates `Delta-Check`,
  `The Waist`); `LENS` stays his word for the four-point figure. His to take or bin.
- **Read-backs Q-1..Q-7** in the notes file, chiefly what `[DR]` stands for.
- **The "simple cell" reference** — he cited a risk model "you just presented"; I find no
  such cell of mine and built one instead, marked mine. If an earlier one exists it
  supersedes.
- **Direction** — `1.1.90` vs `2.0`, or both on branches.
- **A11** — a two-baseline git steer (fast agent-driven vs. run-card/continuation) lost
  to an aborted turn; carried nowhere on disk. Corwin's call whether it is still wanted.
- **A3** — the ruling says "the v1.0 as built for FSF"; the artifact it accepted is the
  v0.9 body. Settle by new record, never by editing t1.
- **T4 residual** — t2's license is now set, but the document names partners and its
  tracker names volunteers; consent to circulate is still owed (PRINCIPLES clause 5).
- **A14** — three questions from 2026-08-20 never answered: context isolation, whether
  SAVANNAH v1.0 is the principle source, seam paranoia level.
- **A7** — Bryant's business name and website still placeholders in the t0 kit.

## Standing guards learned here
- Don't invent a position and attribute it to Corwin (the Bryant "deferral" fault,
  2026-08-24). Check claims against what he actually said.
- Memory upkeep is mine to run, not his to approve. Ask about canon-binding
  requirements; never ask permission to keep the record current.

## 2026-09-30 turn: the review brought home (Acts I and II)
*Appended by the instrument, 2026-09-30. Nothing above was edited; see "Not touched" below.*

**Landed, all new records:**
- `PAPER-2026-09-30-act-1-…` and `CITATIONS-…`, the Act I SWOT and floor. Its §5a holds 17 corrections.
- `LENS-2026-09-30-plaid-act-2.md`, Act II's three rows.
- `operating-model-BASE-1.0.60.md` and its `.sha256`, a working draft. **1.0.51 still governs.**
- `MODEL-2026-09-30-plain-rules-for-ai-help.md` and `CARD-…`, the minimal model and its one-page card.
- `DESIGN-2026-09-30-experiment-whose-plants-count.md`.
- `bin/`: seven floor tools plus `floor-selftest.sh` (7 of 7 pass on this machine; prove-red 9 of 9).
- The full turn record is in `turn-2026-09-30/`.

**Open, and whose:**
- [HIS] Bless 1.0.60, or not. Read its "For the keeper" list first.
- [HIS] Is CORWIN sheet §33 his? Its heading says "in Corwin's own words", and the text locates nowhere else.
- [HIS] What "Author" means on a file the instrument drafted.
- [HIS] Edition numbers for the four shelf pieces.
- [HIS] Two lines framed as his words that locate in no signed file: "Walk toward the weak point…" and "…your
  résumé is our résumé".
- [HIS] The lens skill's "a persona shows reasons, not decisions" paragraph. Its own falsifier fired in one model
  family (row 2).
- [HIS] Cross-family readers, and publication outside the shelf.
- [MINE] The Savannah copies under `turn-2026-09-30/act1/r2/P5B/fetched/*.savannah` and the patch are fenced from
  publication. Deleting them needs his permission.

**Guards learned this turn:**
- A check counts as able to fail only on faults someone other than its author planted. Authors' own plants were
  all caught; others' plants 3 of 57.
- Never route around a fetch refusal (robots.txt). One Act I arm did; the facts were re-attested from a permitted
  fetch and his clone.
- Do not correct a cited record in place. Hash-pinned checks downstream go RED. Supersede by new record (ERRATA),
  as the canon says.
- A person sheet leaks into claims about the person: an owner line naming him; a "his own words" heading over
  unlocated text. Check owner lines on anything drafted while wearing a sheet.

**Not touched (currency, per the project's rule to discuss first):**
- This file's header still says "Working version: 1.0.50"; BASE is 1.0.51.
- README calls `operating-model.md` the governing model.
- COMMENT-ANCHORS' surface table shows `H:\ta`'s last anchor as A1.
I would update all three; I have not, and say so here.
- *Erratum, 2026-10-01 UTC (ERRATA-2026-10-01-act-2.md ERR-001):* "others' plants 3 of 57" above counts two
  positive controls. Like for like, others' faults were caught 1 of 55. The guard stands, and the evidence for it
  is stronger.
