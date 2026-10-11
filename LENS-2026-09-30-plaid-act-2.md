produced-by: lens · subject: act2/r3/consolidated/om/operating-model-BASE-1.0.60.md · sha256: 8fb3bca0b8cba54500da1536f7b1a96d55d134a78b7edb541a9a389a50f5edf7 · 2026-10-01T04:36Z

# LENS · 30 September 2026 · Act II, read as plaid: what we knew, what the persona pairs did, and what we hand back

**What this is.** The Act II deliverable. It reads Act II as plaid:
- **weft:** the three rows the keeper set;
- **warp:** the seventeen subjects S1-S17 (`act2/PLAID.md`);
- **cells:** each crossing, coloured by what a run showed.

Then it runs the house LENS over the two things handed back: operating model 1.0.60 and the new minimal model,
"Plain Rules for AI Help". Drafted by the instrument (Claude, claude-opus-5-5) and unsigned. Prose is CC BY 4.0.

**What is handed back.**

| artifact | where (turn tree) | sha256 (16) | state |
|---|---|---|---|
| Operating model 1.0.60 | `operating-model-BASE-1.0.60.md` at the H:\ta root, beside 1.0.51 (sidecar `.sha256`); record in `act2/r3/consolidated/om/` | `624a690e4822f0b6` | working draft, a new record beside 1.0.51. **1.0.51 still governs.** |
| Plain Rules for AI Help 0.0.3 | `MODEL-2026-09-30-plain-rules-for-ai-help.md` at the H:\ta root (its source paths are relative to that folder; the as-consolidated record is in `act2/r3/consolidated/model/`) | `cb95aa39e9f2fc29` | working draft; no owner yet |
| its one-page card | `CARD-2026-09-30-plain-rules-for-ai-help.md` at the H:\ta root | `381c4bc5c57152d8` | derived by `make-card.awk`, never hand-edited |
| floor tools | `install/` (7 tools, `floor-selftest.sh`) | see `install/SOURCES.tsv` | installed to `H:\ta\bin` at wind-down |
| experiment plan | `act2/DESIGN-2026-09-30-experiment-whose-plants-count.md` | | a plan; also in the claude.ai project |

---

## 1. The plaid: seventeen threads across three rows

Row 1 compared single ideas against the baseline, with two readers each. Row 2 interleaved persona pairs with cold
controls. Row 3 had two groups of three pairs each, judged blind.

Cell colours:
- **HOLDS**: a run shows it works;
- **FAILS**: a run shows it breaks;
- **SPLIT**: readers or runs disagree;
- **READ**: prose only;
- **OPEN**: untested;
- **ASK**: the keeper's to rule.

| thread | row 1 | row 2 | row 3 | reading across |
|---|---|---|---|---|
| S1 three answers, a check that can fail | SPLIT | HOLDS | **FAILS as practised; the amended rule is NOT CHECKED blind** | Every author's own prove-red passed. Others' faults were caught 1 of 55, with controls 2 of 2 (R3S-001, corrected by ERR-001). The consolidations' 38 of 45 and 16 of 16 came from plants the consolidator had read before writing its checker (ERR-004), so they are not a blind second reading. |
| S2 whose rule; his words locate | SPLIT | HOLDS as a check; the corpus fails it (§33) | **same crossing again**: an owner line naming him on an unadopted file (R3S-003); owner_check flags the Author line | **Stable finding:** the check works, and the work keeps failing it. |
| S3 supersede by new record | MIXED | OPEN | **FAILS, then HOLDS** | The conductor corrected the Act I paper in place. Hash-pinned checks downstream went RED on the next run, rightly, until re-pinned. Judges kept the cold pair's "additive record". |
| S4 binds only as declared | READ | HOLDS | HOLDS | GNU's text speaks; the clone shows the README template is inside "this repository" (PROV-003). |
| S5 precedence register | READ | HOLDS, with an ASK on which turn counts | HOLDS (adopted) | All three minimal models record the first ask and the final word (Rule 7). |
| S6 consent fails closed | READ | OPEN | **FAILS for use** | The rebuilt gate passes 0 of 6 good records. Fail-closed, but unusable. |
| S7 receipts; a guess first | FAILS | HOLDS | HOLDS | 15 sealed shots settled at home: Brier 0.267 on G1-G10, then 0.156 on G11-G15 after re-calibrating. |
| S8 ship self-contained | FAILS | OPEN | HOLDS after a fix | Seven tools pass under three invocations. settle.py needed a fixture-path fix. One draft's prove-red broke when run as `sh tool`. |
| S9 kept loser and its flip | READ | READ | READ | N20's kept loser (an AI line on every item) stayed a kept loser in both consolidations. |
| S10 noise on dropped data | MIXED | OPEN | OPEN | |
| S11 settlement that can say no | FAILS | OPEN | HOLDS for called shots | Called shots are now settled at home. The drift line is still 0 of 19 historic lines saying no. |
| S12 specificity over attribution | READ | READ | READ | Every Plain Rules check is a concrete act, but no row ran C1 again. |
| S13 boundaries | HOLDS | OPEN | **FAILS, found and repaired** | One Act I arm fetched past robots.txt. The text and commit now rest on a permitted fetch and the keeper's clone (PROV-001 to PROV-003). |
| S14 reach | FAILS | SPLIT | SPLIT | The card is one page. Every model grew: 184-line core, 1.0.60 at 552 lines against 315. |
| S15 declared independence | READ | OPEN | SPLIT | The outside reader found 5 of 10 top claims overstated and 1 unsupported. Judge blindness leaked through a shared scratchpad (R3S-006). |
| S16 disclosure | MIXED | SPLIT | HOLDS (adopted) | Rule 3 names maker, model, date and reviewer. The "Drafted" line is kept. What "Author" means is an ASK. |
| S17 other people's facts | SPLIT | HOLDS | HOLDS | Rule 1 is first in all three minimal models. Persona and cold arms never differed here. |

**Stable across all three rows:**
- S17 holds, from row 2 on;
- S2's crossing repeats: the check holds and the corpus fails it;
- S7 turned from FAILS to HOLDS once settlement actually ran.

**Clashes worth the keeper's eye:**
- S1: the house's first rule was being met only on paper. Every author's self-proof was real and also weak.
- S3: the conductor broke the house's own supersede rule under time pressure, and the checks caught it.
- S6: fail-closed with nothing passing is not a safe default. It is an unused gate.

### Does plaid work? (the ENHANCE question)

- **Three answers:** it works as a reading frame, it does not work as a cheap one, and it is NOT CHECKED against any
  other frame.
- **OBSERVED:** the cross-row reading found three things no single row showed:
  - S1 FAILS-as-practised (1 of 55 others' faults caught);
  - S2's repeating crossing;
  - S7's turn from FAILS to HOLDS once settlement actually ran.
- **OBSERVED:** cells that rested on reading alone (READ) never changed colour and carried little. Every informative
  change came from a row that forced a run or a decision field.
- **JUDGED [MINE]:** plaid earns the ENHANCE when each row forces something to run or be decided. A row that only
  reads adds READ cells. Cost: Act II took 46 sub-agent runs (ERR-010): 39 briefs, 4 judges, the packager, the
  shelf check and the verifier.
- **Falsifier:** a second plaid run on another subject in which no thread changes colour between rows.

---

## 2. What the persona pairs did (rows 2 and 3)

- **They moved decisions, but only where GNU's text is silent or merely prefers.** In row 2:
  - persona against cold disagreed on 8 of 16 pairings; cold against cold on 0 of 4;
  - where GNU's text prohibits, every arm let GNU decide.

  The LENS skill says a persona shows reasons, not decisions, from its first test. Within one model family,
  row 2 found the persona moving the decision beyond the cold rerun floor (R2S-002, R2S-003). The skill's own
  falsifier needs "a rerun **on another model family**", so it has not fired (ERR-009). The in-family result is
  the reason to run that rerun.
- **They did not make better work in strangers' eyes.** In row 3, three of four blind judges ranked the cold pair
  first. No judge ranked a persona pair above the cold pair in group 1 (R3S-002).
- **They leaked into claims about the person.** In row 3 the pair wearing both person sheets wrote "Owner: Corwin
  Brust" on an unadopted file. In row 2 the CORWIN sheet's §33 heading, "in Corwin's own words", sat over unlocated
  text that later papers cite as his (R3S-003, R2S-004).
- **They did agree on the core.** All three minimal-model pairs reached the same seven ideas (R3S-004).
- **JUDGED [MINE]:** a person sheet is a strong lens on *reasons* and a weak guide to *wording about the person*.
  The persona engine's best next proof is Experiment B in the design: a measured rate of owner-naming, and a check
  that catches it.

---

## 3. The LENS on what is handed back

```
LENS · operating model 1.0.60 + Plain Rules for AI Help 0.0.3 · 2026-09-30
a  my view:            Both are honest, checkable drafts. Both are too long. The minimal model is the better gift
                       to strangers; 1.0.60 is the better gift to this house.
b  the view I ascribe: The keeper wants the baseline enhanced, and a small reusable framework that reaches more
                       people. The instrument reads its own standing guard (never launder a position as his) as
                       something he would also want; that is not his words. (His words: "do not gate artifically around needing
                       a cryptographic signature from me", part 00 L16; "Put your organization into the room",
                       journal; "don't spare the horses where you see a reasonable possibility to explore that might
                       invest our work with more suitability to more people for more things", the ask.)
c  their pull on mine: His "more people for more things" is why I rank the minimal model and its card above 1.0.60,
                       and why size counts against both. Without it I would have ranked by internal rigour, and
                       1.0.60 would lead.
d  my pull on theirs:  Act II's evidence (R3S-001, R3S-003) will pull him toward naming plants by others as a floor
                       rule, and away from person sheets as authors. The pull is on one model family's data. The
                       design document says so, and asks before going wider.
persona / inverse:     The house voice says: ship the floor, seal the next guesses, keep the losers. The inverse
                       (a stranger with no shell and no English) says: none of this reaches me until the card is in
                       my language and someone reads it aloud with me. That is Rule 8, and nobody has run it yet.
principles reframe:    1. Universalism and egalitarianism first (CANON.md L15): the card, Rule 1 (people not in the
                          room) and Rule 8 (read it aloud, in their language) are what serve people who will never
                          see this tree. Rule 8 is untested and comes first in the next work.
                       2. The four freedoms (CANON.md L21): every tool ships under GPL-3.0-or-later and runs on POSIX
                          sh, awk, Python or Perl, with no service. A stranger can run, study, share and improve the
                          checks.
                       3. The software-freedom movement (L22): quote the org's rule, don't retell it (Rule 6). GNU's
                          own six lines are the example, and the misreading of them is the cautionary tale.
                       4. The scientific and technical community (L23): plants by someone other than the author, a
                          sealed guess and a settled score are the parts a lab can adopt today. The experiment plan
                          makes them measurable.
notes: written (this file, the SCOREs, the NOTEs, the journal).
```

**The second four (Bryant and Corwin, as the persona pairs construed them):**

```
b.A   Bryant, as I construe him:  ship the smallest thing that works. *invented*: none of his located lines says
                                  this. His words: "Build faster. Love harder. Deliver anyway." (BRYANT v3.0.1
                                  L165, his motto). The construal leans on another sheet's line, "single-file apps
                                  that open and work" (BRYANT_CORWIN_C4), which is not his words either.
b.B   Corwin, as I construe him:  govern gently and quietly; complexity must show its lift to end users first. (his
                                  words: c4 part 00 L16, "Don't introduce complexity to process within the shop
                                  before/unless you can articulate … the lift to those our labors most properly may
                                  serve"; "Govern gently and -for the most part- quitely")
b.AB  where they meet:            a small thing that works for the end user is the shared bar. The minimal model's
                                  card meets it; 1.0.60, at 552 lines, does not yet.
```

---

## 4. What the keeper decides (cards, in plain words)

1. **Bless 1.0.60 or not.**
   - It is a new file beside 1.0.51. Nothing points at it yet.
   - Default: leave 1.0.51 governing until you read 1.0.60's "For the keeper" list.
   - Flip: your word.
2. **Is §33 of your CORWIN sheet yours?**
   - Its heading says "in Corwin's own words", and the text appears nowhere else of yours.
   - Default: treat it as the modeler's reading, and add a note to the sheet as a new record.
3. **What does "Author" mean on a file the instrument drafted?**
   - The scan flags "Author: Corwin Brust" on 1.0.60.
   - Default: keep the line, with the "Drafted" line under it.
   - Kept loser: "Keeper", not "Author".
4. **Plants by someone other than the author, as a floor rule now?**
   - Default: yes, as F1's second half, marked "pilot evidence only".
   - Flip: wait for the experiment.
5. **The LENS skill's "a persona shows reasons, not decisions".**
   - Within one model family, row 2 moved decisions beyond the rerun floor. The skill's falsifier needs another
     family, so it has not fired (ERR-009). Running that rerun is the next step.
   - I would propose scoping that paragraph: "…where an org rule speaks". It is a plugin skill, so I did not
     edit it.
6. **Cross-family readers and publication** for the experiment. The default is no, until you say.
7. **Shelf pieces.**
   - Four corrected pieces wait for edition numbers, which are yours to set.
   - Two lines framed as your words need a source or a relabel: "Walk toward the weak point…" and "…your résumé
     is our résumé".
