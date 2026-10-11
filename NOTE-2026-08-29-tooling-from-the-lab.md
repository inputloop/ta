# NOTE — tooling available from the lab, and the line it must not cross

> **LOCAL FILE. Hub root, never shipped.** Per the kit's own preference, a local root may
> name the local context; **core and shipped material may not.** Nothing on this page may be
> lifted into `operating-model-BASE.md`, `operating-model-CORWIN-ORG.md`, any instance's
> model, or anything `ship.sh` passes.
> **Written at Corwin's express direction, 2026-08-29** — *"leaving/updating notes in the
> /h/ta project root to help guide that project to the tooling."*
> **Status.** Note, not canon. Unblessed. Wants an anchor row (**A26**) if it is kept.

---

## Why this note exists

A tool arrived here once without its viewpoint, and this project could not read it as well as
it deserved. That is a **reading** failure, not a writing one — the same class as every
finding in the drift pass below. The tree recorded fine; nothing carried the frame across.

So this page is the frame. It is short on purpose.

## The line

The lab is a separate project and this one is **completely unbound from it.** This project
may lift **method**. It may not carry the **name** — not in the baseline, not in the kit, not
in any localized instance, not in anything shipped. That is not a permanent state: it lifts
when the lab is closer to *proven* (an install and uninstall demonstrated on the new host, and
something in Bryant's hands he can start working with). It is a proof gate, not a publicity
gate.

Practical version, for anyone working here:

- **A tool in `bin/` is fine.** Tools are utility.
- **A note in this root is fine.** This root is local.
- **A tool's OUTPUT is the risk surface**, because output lands in documents. Check what a
  tool emits before pasting it into anything the kit ships.
- **If a method is worth keeping, rewrite it in this project's own words.** That is a
  success, not a rejection — the method crossed and the name did not, which is the whole
  arrangement.

## Take a tool twice: once for utility, once for method

Every tool offered here is two things and you are entitled to either without the other.

**Utility** — it does a job today, carries none of the lab's data, and nothing about its
origin is load-bearing to whether it works.

**Method** — its shape is an argument about how to work, and the argument is liftable even
where the tool is not. **Lift the method with its falsifier attached.** A behavior without
the check that fails it is half a lift, and the half that carries no weight.

## What is on offer right now

### 1 · `drift.sh` — the one this project is actually missing

`DRIFT.log` here carries a `format:` header and there is **no tool in `bin/` that writes
it**. The log is typed by the same hand it audits. `t0` has had the tool since 2026-08-22
(530 bytes, POSIX, no dependencies); a copy is staged and byte-identical
(`0678cc12…c830f5`, checked at both ends).

Three findings from a drift pass on 2026-08-28/29, all re-derivable from these trees:

- **The kit's own log went dark across the v1.0 cut.** Last checkpoint `2026-08-23T06:57Z`;
  **seven commits followed**, covering v0.6 → v0.9 → 1.0-candidate → v1.0, the sign, the tag,
  the ship. `CHANGES.md` and `MODEL-DRIFT.md` were *updated* on the 24th — so the narrating
  surface stayed green while the catching surface went dark. `drift.sh` is a separate act at
  the end of a turn, and that is exactly the act dropped when a turn ends in ceremony.
  **Fix: chain it into `cut-*.sh` and `ship.sh` so a release cannot be cut without a
  checkpoint.**
- **Eighteen checkpoints across both logs. Eighteen `on-bearing? yes`. Zero noes.** By this
  project's own `MEASURES.md`, *a checker that never fails scores zero*. Every other
  instrument here ships planted failures — `measure-guard` catches two, `riskcell` 3/3,
  `bearing.sh` catches `B-BAD` and `B-ZERO`. Drift is the only one with no falsifier, and it
  is the one whose whole job is noticing that something quietly stopped being true.
- **The two logs do not know each other exists.** One reads current at 1.0, one at 1.0.51,
  both look fresh. A header line naming siblings and their last-checkpoint dates closes it.

### 2 · The 17% / 9% wind-down budget wants a `measures.tsv` row

Landed here on the 28th at 1.0.51. Taking drift's share **last so it does not skew the
others** is a real insight. But it has no row, no `dir`, no `basis`, no Probe A/B — and by
this project's own canon that makes it inadmissible. Worse, *"reserve 17% of the run"* is
**volumetric on its face**, a fraction of tokens or wallclock, the two things `MEASURES.md`
explicitly fences as cost-only.

It survives only if what is measured is **whether the wind-down happened**, not how much was
spent on it. That distinction is not written down anywhere yet, and it is heading for a talk.
Suggested row: `winddown_kept · ratio · per-run · up-good · non-volumetric · counted` —
*share of runs that produced their wind-down artifacts before the budget closed.* Then run
the guard on it. If it fails Probe A, better to learn it here than in the room.

### 3 · A cube for the `BOTH` rows in the slide catalogue

Your own hand-edit changed `BOTH` to **"draft as CORWIN gives a middle."** There is a small
tool that takes that literally: for a given slide it declares the **axes**, enumerates the
**stops** (each stop a whole answer, written by a hand, never composed by the tool), applies
the declared **tensions**, and prints only the coordinates that survive.

Slide 34 comes out as three axes, 27 cells, **16 legal and 11 refused** — each refusal
carrying the sentence that refuses it. The answer is then one line, not an essay:
`MOVE 34@risk2.room1.land2`, or `HOLD 34 <what is wrong with the axes>`.

The method is the liftable part and it is one sentence: **where the answers are foreseeable,
enumerate the axis instead of asking an open question — and show the tension, because a
control that hides coupling lies about the design.** Seeded on #34, #11 and #52. The axes are
one hand's judgement and want striking freely.

### 4 · Batch your changes as a token stream

Not offered as a tool — its vocabulary is reserved lab-side. **The idea is offered**, and it
is worth having: write a batch of changes as a stream where every line either resolves to one
act or is kept verbatim as a comment. **No error state.** That means prose may be typed
anywhere in the batch, including mid-decision, and nothing breaks.

Built here in the receiving project's own words, that gives you a change-batch you can hand
to a person or a machine and neither has to translate first.

## Loose ends in this tree, found while reading

- **Eight prose files carry `.sha256` sidecars and all eight verify MATCH today.** Good.
- **Four data files carry none** — `measures.tsv`, `probes.tsv`, `risks-lab-teardown.tsv`,
  `bearing-lab-teardown.tsv`. **The tools read the data.** The prose is pinned and the
  instruments' inputs are loose; the seam runs the wrong way round.
- **`SLIDES-catalogue_hand-edits--CORWIN.md` has no sidecar** while its sibling does.
- **The three `SUPERSEDED-*` files correctly have none** — `.project.yml` says they stay
  unstamped so their bytes stay as recorded. **That is a designed gap. Leave it.**
- `.project.yml` and `MEMORY.md` are still stale against anchor A13, as `DRIFT.log`'s
  2026-08-28T00:00Z entry already says of itself.

---

*Note only. Where this page and this project's own canon disagree, this project wins — that
is rule 4 of its own model, and it outranks anything offered from outside.*
