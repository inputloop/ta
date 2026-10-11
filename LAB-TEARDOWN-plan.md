# Lab teardown and rebuild — plan

> **Author.** Corwin Brust &lt;corwin@bru.st&gt;, 2026. **License.** CC BY 4.0 (docs) /
> GPL-3.0-or-later (code). **Version.** 1.0.50 — working draft, unblessed.
> **Method.** A **called shot**, run by `operating-model-BASE.md` v1.0.50. This plan is
> also the worked example that proves the method: every number below is computed by
> `bin/riskcell.sh` and `bin/bearing.sh`, not asserted.

## What we are actually doing

Not "cleaning the lab." Two outcomes, and the second is the point:

1. **Make a flat surface** — a real table where two people can sit and both write. The
   trigger was concrete: David had no good table option at dinner, and the full form of
   pair note-taking (both take notes, swap periodically) **cannot run without one.** The
   surface is not comfort; it is the apparatus for a method.
2. **Bundle the cabling better** — pull each run closer to the next unconnected or
   not-quite-ideally-connected device or tower, so the topology stops being a thing
   held in memory.

The larger practical goal, stated by him: **the Empyrean side.** The left side of the
workspace, where work materials spread out and Empyrean's device sits on the nearest
screen — which typically has only the one.

## Sequence and hands

Teardown moved to the **three-day weekend** (his update this session). The pattern he
named:

| when | who | what |
|---|---|---|
| before | Corwin | finish planning; see the improvements before starting |
| Sat | Corwin + Bryan (+ kids as extra hands if needed) | teardown, the bulk move, cable runs |
| Sun | Corwin + Dee | land the delicate bits |
| Sun night | — | **all back full** — movies. The hard deadline. |
| Mon (holiday) | — | slack, and the reason the deadline is survivable |

**The deadline is the design constraint.** "All back full for movies Sunday night" is
what makes the risk band on R-SLIP worth pricing rather than shrugging at.

## The guess (beat 1 — recorded before the try)

Per the loop: state it before, settle it after. **These are guesses, not estimates.**

| guess | value | how it will be settled |
|---|---|---|
| G-1 · wall time, teardown through rebuild | **14 hours** across the two days | logged start/stop per session |
| G-2 · share that will not work first try | **25% non-functional** at first power-up | count of devices needing a second pass |
| G-3 · devices that come back mis-cabled | **3** | count at first power-up |
| G-4 · scope expansion | **2 items** beyond this plan's list | anything done that is not on the in-scope list below |
| G-5 · expected cost of the priced risks | **$550** | `bin/riskcell.sh` roll-up, re-run after |

`guess_delta` and `guess_calib` from `measures.tsv` are settled against these five rows.
That is the whole reason to write them down, and it costs about four minutes.

## Risks — priced, per RISK-CANON

Run: `sh bin/riskcell.sh /h/ta/risks-lab-teardown.tsv 75`
(`TIME_RATE=$75/hr` — **declared here, not assumed**; change it and re-run rather than
arguing about it in prose.)

| id | what happens | occur | cost | expected | band |
|---|---|---|---|---|---|
| R-SCOPE | teardown expands past the plan | 50% | $450 | **$225** | $113–$338 |
| R-CABLE | mis-seated bundle, device unreachable | 60% | $225 | **$135** | $68–$203 |
| R-SLIP | not landed by Sunday movie night | 35% | $300 | **$105** | $53–$158 |
| R-DELICATE | a delicate component damaged | 10% | $550 | **$55** | $28–$83 |
| R-EMPYREAN | left side not usable Monday | 20% | $150 | **$30** | $15–$45 |

**Roll-up: $550 expected.** Independence caveat, stated rather than buried: **R-SLIP and
R-EMPYREAN are not independent** — the left side is scheduled last precisely so it
absorbs slip, so the two move together and the roll-up mildly over-counts. The honest
read is *roughly $500, and the two big rows are both about discipline rather than about
equipment.*

**Refused — these stay CONCERN, and the tool will not let them be called risk:**
- `C-DUST` — dust and thermal state after the move. No estimate, no cost, no receipt.
- `C-KIDS` — extra hands Saturday. Depends on the weekend; not counted.

That refusal is the canon working. Two things everyone would *feel* are risks are not
priced, so they do not get to borrow the authority of the five that are.

## The bearing pass — SP/UF on my own claims

Run: `sh bin/bearing.sh /h/ta/bearing-lab-teardown.tsv 20`

The register prices the hazards. This prices **the claims this plan makes**, and it is
less flattering:

| claim | rung | SP/UF | read |
|---|---|---|---|
| labelling ends prevents most rework | 1 | 1.00 | calibrated |
| the Sunday deadline holds | 1 | 1.00 | calibrated |
| scope will expand about two items | 0 | 2.25 | **over-claim** — ordinal confession, and it still shows more than it understands |
| the surface will support full pair-notes | 1 | 4.00 | **over-claim**, and the face is a `count` — padding exposure live |
| left side usable Monday morning | 1 | 4.00 | **over-claim** |
| Dee lands the delicate bits Sunday | 2 | 0.20 | **under-claim — buried lead** |

**Three findings, and I would not have got them from prose.**

1. **The surface claim is the weakest thing in this plan**, which is awkward, because the
   surface is the *reason for the plan*. I have an inventory of what fits on the bench and
   no read on whether two people can actually both write there. That is a `count` face,
   and the tool says so. **Fix before the weekend: sit two chairs at the intended spot and
   try it.** Ten minutes, and it converts the plan's premise from assertion to reading.
2. **"Left side usable Monday" is over-claimed for the same reason** — confident plan,
   thin understanding. It rides entirely on being scheduled last, which is a hope about
   sequencing, not knowledge about the space.
3. **Dee's part is under-claimed by a factor of five.** The best-grounded thing in the
   whole plan — long practice, one incident in about ten comparable moves — gets one line.
   That is the buried lead the base model warns about, showing up in my own document.
   The delicate bits are the part most likely to go right, and the plan reads as though
   they are the part to worry about.

## What the numbers say, plainly

**The two biggest rows are behavioural, not physical.** R-SCOPE ($225) and R-CABLE
($135) together are two-thirds of the expected cost, and neither is about hardware:
one is the standing scope-expansion row, the other is unlabelled cable runs. The
delicate-component row everybody worries about is **$55**.

So the plan's leverage is in two cheap moves:

- **Label before you unplug.** A tape flag on each end of every run, written before
  anything moves. Directly attacks R-CABLE's stated basis (*unlabelled runs are the
  common factor in 3 of the last 5 rebuilds*). Cost: perhaps 45 minutes. Expected
  saving: most of $135.
- **Write the out-of-scope list first, and treat it as the receipt.** R-SCOPE's basis is
  his own named failure mode; the plan's own out-of-scope list is what makes the row
  checkable afterward. Cost: ten minutes.

## In scope

- Flat work surface established and clear.
- Cable runs bundled and **labelled at both ends**, pulled toward their nearest device
  or tower.
- Left/Empyrean side rebuilt last and verified: device on nearest screen, single-screen
  layout usable.
- Delicate items moved Sunday with Dee.
- Power-up pass with a device checklist; second pass for whatever fails.

## Out of scope — the R-SCOPE receipt

Written before the work, so afterward the row settles honestly. Anything here that gets
done anyway is a scope expansion, and that is a finding, not a scolding.

- Reorganizing storage or media that is not blocking the surface.
- Re-imaging, upgrading, or "while I'm in there" maintenance on any device.
- Rewiring the network beyond bundling existing runs.
- Cataloguing or archiving anything.
- Any project that begins with the words "since it's already apart."

## Test (beat 3) — how the weekend is settled

Not "does it look better." Falsifiable:

1. Power-up pass: count devices non-functional on first try → settles **G-2**.
2. Count mis-cabled devices → settles **G-3**.
3. Sum logged hours → settles **G-1**.
4. Diff work done against the out-of-scope list → settles **G-4**.
5. Re-run `riskcell.sh` with what actually happened → settles **G-5**.
6. **Two people can sit at the surface and both write.** The binary one. If that fails,
   the teardown did not achieve its stated purpose regardless of how the room looks.

## Write (beat 4)

One `DRIFT.log` line at the hub, the settled guess table appended here, and — if the
surface works — the **full** pair-note method gets its first run, which is the thing all
this was for.

## Collision worth naming, not resolving

**Friday 2026-09-04, 13:00–14:00 ET** is the FSF front-door hour on the t1 calendar, and
it sits on the Friday of this same long weekend. Not a conflict on its face; it is the
day before teardown starts. Flagging it because a rearranged lab on the Friday and a
live meeting on the Friday are the kind of thing that collides quietly.

---

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
