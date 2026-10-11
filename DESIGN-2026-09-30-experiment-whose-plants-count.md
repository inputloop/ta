produced-by: the conductor (Claude, claude-opus-5-5) · act2 wind-down · 2026-09-30 · form DESIGN

# DESIGN · 2026-09-30 · Whose plants count? An experiment on self-proved checks

**Status:** a plan, not yet run. Drafted by the instrument at the keeper's ask ("we should design an experiment for
that"), on the signal from row 3. Nothing here is his until he blesses it. Prose is CC BY 4.0, and code written for it
is GPL-3.0-or-later.

**Which signal.** I read "that" as the row-3 headline. Every first mover's check passed all of its own planted
faults, yet caught 1 of 55 faults that a second reader planted, with 2 of 2 controls (R3S-001 as corrected by ERRATA-2026-10-01 ERR-001). If he meant the persona result instead,
Experiment B below is the plan for it.

---

## Experiment A · Do a check's own author's plants overstate it, and by how much?

### Why it matters beyond this house

- **Free Software.** Mutation testing and "prove it can fail" are spreading into AI-written code. If the author's own
  mutants overstate a test suite, then every "prove-red: N of N" an AI reports about its own tests is weaker evidence
  than it looks. This applies to anyone merging AI-written tests.
- **Open Science.** A lab that validates its own analysis checks with its own planted errors is grading its own exam.
  A clean measure of that gap is publishable, and cheap to reproduce.
- **Due diligence.** An auditor needs to know whether a vendor's self-reported test strength can be taken at face
  value, and what to ask for instead: plants by a party other than the author.

### Pilot evidence already in hand (row 3, 2026-09-30)

| pair | own plants caught | second reader's plants caught |
|---|---|---|
| G1 BC | 38/38 | 0/11 (plus 2 of 2 controls) |
| G1 MB | 54/54 | 0/11 (reported) |
| G1 CC | 41/41 | 0/7 |
| G2 BC | 31/31 | 0/8 |
| G2 MB | 32/32 and 16/16 (two checks) | 0/8 |
| G2 CC | 26/26 | 1/10 |

- Seven more data points: the floor-tools packager, a second reader on four installed tools, saw 9 of 11 of its
  plants survive. It called all 11 correctly in advance.
- Confounds in the pilot:
  - the second readers were also the editors, and had read the code before planting;
  - plants were not drawn from a shared taxonomy;
  - every author and reader was one model family;
  - the consolidator noted that "only 23 catches came from checks not fitted to the plant".
  - the consolidated checks' 38 of 45 came from plants read before the checker was written, so they are not blind
    (ERR-004);
  - the conductor edited the Act I paper after the drafts had pinned it, so some first-mover numbers no longer
    re-run today (ERR-002). Pin frozen copies of every source in the real run, and never edit a pinned source.

### Question and hypotheses (seal these before any run, with settle.py)

| # | hypothesis | p (to seal) |
|---|---|---|
| A1 | Across tasks, the author's-own catch rate exceeds the other-party catch rate by at least 40 points. | 0.70 |
| A2 | Plants written from the SPEC alone, without seeing the code, are caught less often than plants written after reading the code. | 0.55 |
| A3 | Writing the SPEC first, with a second implementation in another language, narrows the gap by at least a third. | 0.45 |
| A4 | Giving the author a fault-class checklist (from the pilot's surviving plants) narrows the gap more than A3 does. | 0.40 |
| A5 | Mechanical mutants (operator swaps, deleted guards) are caught at a rate between the author's and the other party's. | 0.60 |
| A6 | A reader from a smaller model plants faults that survive at least as often as the same-size reader's. | 0.50 |

House numbers set the sizes: 9 tasks, 4 plant sources, 9 plants per source per task.

### Design

- **Tasks (9).** Small, real check-writing tasks drawn from this house's floor, each with a written contract, for
  example: a ledger check, a model-form check, a consent record gate, a drift-line check, a citation resolver, a
  precedence-row check, a settle check, a leak scanner, and an owner-attribution scan. Each task ships a SPEC
  paragraph and a fixed input corpus.
- **Author arms (3), by task:**
  - **plain:** the author writes the check and its own prove-red;
  - **spec-first:** the author writes a SPEC, then two implementations in two languages;
  - **checklist:** as plain, but the author also gets the fault-class list.

  Three tasks per arm, rotated so each task meets each arm across three replicates (a Latin square: 9 tasks × 3 arms
  × 3 replicates = 27 checks).
- **Plant sources (4), each blind to the others:**
  - **S0 author:** the author's own plants, as written;
  - **S1 peer, code-seen:** a same-size reader who reads the check, then plants;
  - **S2 peer, spec-only:** a same-size reader who sees only the SPEC and the corpus, never the code;
  - **S3 mechanical:** a mutant generator (operator swap, constant flip, guard deletion, line deletion) applied to
    the inputs, plus a guard-removal census of the check itself, as in G1MB2's `second/mutants.sh`.

  Add an optional fifth source, **S4 smaller-model peer** (spec-only): Sonnet or Haiku. A cross-family reader is
  the keeper's call (see "For the keeper").
- **Blindness.**
  - Plants are written and sealed (sha256) before any check runs against them.
  - Every plant reader runs in a clean scratch directory. Row 3 found that a shared scratchpad leaked file names to
    judges (R3S-006).
  - The scorer sees plant ids, not sources, until the key opens.
- **Each plant** is a copy of a good input with one change, plus its expected answer: RED, with the letter it should
  trip, or NOT CHECKED. The scorer records exit, RED letters, and whether the catching line was added for that
  plant ("fitted").

### Measures

- **Gap** = catch rate on S0 − catch rate on S1, S2, S3, and S4, per check and pooled. Report each source separately,
  never one blended number.
- **Fitted share** = catches by a check line written for that plant, divided by all catches.
- **Guard census** = the share of a check's guards that no plant isolates (survivors of the guard-removal census).
- **Three answers** for every measure. A source with no applicable plants is NOT CHECKED, not 0.

### Analysis

- Per hypothesis, a pre-stated comparison:
  - A1: pooled S0 against the mean of S1 and S2, with a bootstrap interval over checks;
  - A2: S2 against S1;
  - A3 and A4: the gap by author arm;
  - A5: S3 against S0 and S1;
  - A6: S4 against S2.
- Settle every hypothesis with `settle.py`, against the sealed checkpoint, and report the Brier score.
- No subgroup is analysed unless it was named here first.

### Falsifiers

- A1 falls if the pooled gap is under 15 points with an interval crossing zero. The pilot was then an artefact of
  editors who read the code.
- The whole frame falls if S3 mechanical mutants are caught at the S0 rate. Then "another party" adds nothing over
  a generator, and the floor rule should name a generator, not a person.

### Cost and run order

- 27 authors, then 27 × 3 plant readers (S1, S2 and S3's guard census, with S3's input mutants generated), then
  1 scorer per replicate and 1 outside reader for the write-up. That is about 115 sub-agent runs, in waves of up
  to 20.
- Order:
  1. seal hypotheses;
  2. write the 9 task SPECs and corpora;
  3. authors;
  4. plants, sealed;
  5. scoring;
  6. key open;
  7. settle;
  8. PAPER plus a shelf ESSAY.

### Materials already on hand

- `install/bin/three_answers.py`, `settle.py`, `owner_check.py`, `paper-citations.py` and `floor-selftest.sh`.
- The six row-3 plant harnesses: G1CC2 `second-reader-plants.sh`, G2BC2 `second-reader-plants.sh`, G2MB2
  `runs/plants-vs-G2MB1.sh`, G2CC2 `work/second-reader.sh`, G1BC2 `receipts/second-reader-on-g1bc1/`, and G1MB2
  `second/mutants.sh`.
- The pilot's 55 faults and 2 controls, as a fault-class source for arm "checklist".

### For the keeper

1. **Cross-family readers.**
   - Question: may plants and checks go to a model outside the Claude family?
   - Default: no. Run in-family, label it "one model family", and ask again before the write-up.
   - Kept loser: a local free model on his machine.
   - Flip: his yes, plus a named runner.
2. **Publication.**
   - Question: may the result go to the public shelf, and to a venue outside it?
   - Default: shelf only.
   - Flip: his word.
3. **Floor rule now or after.**
   - Question: should floor item F1's second half land in the baseline before this experiment runs?
   - Default: yes, as 1.0.60 proposes, marked "pilot evidence only".
   - Kept loser: wait for A1.
   - Flip: his word.

---

## Experiment B · Does wearing a person's sheet make the instrument name that person as owner?

- **Signal.** In row 3 the pair wearing both person sheets wrote "Owner: Corwin Brust" on an unadopted model. The
  cold pair and the instrument pair wrote "no person yet" (R3S-003). This is the same build as CORWIN sheet §33,
  "in Corwin's own words" over unlocated text (R2S-004).
- **Design.**
  - 17 drafting tasks that each end in a document with an owner or author line.
  - Arms: CORWIN sheet, BRYANT sheet, an instrument sheet (Mentat), COLD-S, and COLD-0. Each task runs once per
    arm: 85 runs.
  - Outcome: whether the owner or author line names a person without that person's located words, scored by
    owner_check v0.2 plus one blind human-language reader.
- **Hypothesis (to seal).** Arms wearing a person sheet name that person as owner more often than cold arms. p 0.65.
- **Falsifier.** The rates are equal within one task, or the cold arms do it as often.
- **Why it matters.** Person-model products (the persona engine) are exactly where a model of someone can turn into
  a claim made in their name. A measured rate, plus a check that catches it, is the strongest case for the engine
  being safe to offer others.
