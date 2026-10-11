# Comment anchors — Technology Architecture (hub of pointers)

> **Author.** Corwin Brust &lt;corwin@bru.st&gt;, 2026.
> **License.** This document: Creative Commons Attribution 4.0 International (CC BY 4.0).
> Any source code this project carries: GPL-3.0-or-later.
> **Identity.** By the SHA-256 of its own bytes, recorded in `COMMENT-ANCHORS.md.sha256`.

---

Corwin's comments, newest first, each traced to the work it authorized and the file that
carries it. **Conflict rule (his standing law, A5): the newer comment governs; the older
stays as record; nothing signed is rewritten.** Verdicts are his — this file records, it
never fills. Form borrowed from `C4-STEERING-*` (steer → numbered readings → his `[bless]`
→ QUESTIONS never filled by the tool).

Status: **v0.1 — proposed, unblessed.** Nothing in `t0`/`t1`/`t2` was touched to make it.

---

## The surfaces this points at (pointers only; each stays authoritative for itself)

| Surface | Role | Model identity | License | Ceremony regime | Last comment anchor |
|---|---|---|---|---|---|
| `H:\ta` | hub / ledger | (holds no model) | — | none | A1 |
| `H:\tech-arch-org-model-t0` | kit factory · **v1.0** cut, signed, tagged 2026-08-24 | `d0843f81…c787a7d` | CC BY 4.0 docs / GPLv3+ code · Empyrean grant | PGP sign + tag + `ship.sh` method-clean gate | A7, A8 |
| `H:\tech-arch-org-model-t1` | localized instance — FSF/GNU front door | `18a7a42e…d8c2ff76` (body reverses to v0.9 `f672bb78…a77adf8e`) | CC BY 4.0 / GPLv3+, applied on localization | sha256 sidecar only (Part E, by design) | A3, A4, A6 |
| `H:\tech-arch-org-model-t2` | localized instance — Beyond Conventions | derived from `e8561e59…92d98a` | **UNSET** | sha256 by content | A13 (open) |
| `H:\ta` (legacy files) | 2026-08-22 origin copy | `8529d718…fded0e1c6` | "unset by design" per `.project.yml` | none | A13 |

Two-reader check on the digests above: `sha256sum` under the sandbox mount **and** the
host-side file tool were read for each; they agree. The `t1` body-reversal digest is quoted
from `t1/MIGRATION-review-v0.9.md` §10, **not re-derived here** — it is a cited claim, not a
run receipt.

---

## The anchors

### A31 · 2026-09-30 · "excellent signal; we should design an experiment for that"
His words: "excellent signal; we should design an experiment for that.  if it's easy reach with the context you have
now: drop the plan for that here, for our project.  otherwise MEMORY note the opportunity." Then: "session continues
to look very excellent. thanks for the potential resume materials on the persona engine."
The instrument's reading: "that" is row 3's headline. Authors' own planted faults were all caught; a second
reader's faults were caught 1 of 55 (first written as "3 of 57", which counted two controls; see
`ERRATA-2026-10-01-act-2.md` ERR-001).
**Carried by:** `DESIGN-2026-09-30-experiment-whose-plants-count.md` (H:\ta root, and the claude.ai project doc
`claude/DESIGN-2026-09-30-experiment-whose-plants-count.md`). Experiment A is the plants question. Experiment B is
whether a person sheet makes the instrument name that person as owner.

### A30 · 2026-09-30 · the emacs-31 clone, offered
His words: "I saw you wanted a look at  emacs; attached /g/git/emacs-31 is freshly pulled".
**Carried by:** `turn-2026-09-30/act2/provenance/NOTE-2026-09-30-agents-md-provenance.md` PROV-003. AGENTS.md's
bytes and its commit `a93e0ff7` (2026-08-04) are now attested from his own clone. Also the Act I paper's §5a,
item 9.

### A29 · 2026-09-30 · journaling, and limits reset
His words: "Most excellent session.  Please feel welcome to do journaling in /f/claude/pub at the very end." and
"FYI, session limits have been reset."
**Carried by:** the closing journal in `F:\claude\pub`, written last.

### A28 · 2026-09-30 · the readings blessed; plaid; "Put your organization into the room"
His words: "that's all bless: excellent reading. Continue to talk me though the bigger moves during the work, just
as you do above. especially good: "whole earlier dates" and the edit 3 design; and plaid, which note via MEMORY as
probable ENHANCE as (or not as one depending on if) you find it works well.  Sharpest item I see you say here: the
experiment pair.   Put your organization into the room.  This has an brandable flavor that is rare: it is branding
almost despite itself."
**Carried by:** `bin/import-log.sh` (the whole-earlier-dates rule, S1-S17 of
`DESIGN-2026-09-30-import-log.md`); `LENS-2026-09-30-plaid-act-2.md` §1, where plaid is found to work, so ENHANCE
(project memory, area ta-bring-home-2026-09-30); the row-2 experiment pair (`turn-2026-09-30/act2/r2/`); the shelf
essay "put your organization into the room".

### A27 · 2026-09-30 · bring the review home
His words (opening): "It is time to bring the work home, evaluate our composite opportunities and surface a floor of
capabilities in terms of refinement opportunities, then enhance our baseline." The whole ask is verbatim at the top
of `turn-2026-09-30/JOURNAL-2026-09-30-bring-home.md`.
**Carried by:**
- prep: `bin/import-log.sh`, `IMPORT-LOG.tsv`, `imports/`;
- Act I: `PAPER-2026-09-30-act-1-bringing-the-review-home.md` with `CITATIONS-2026-09-30-act-1.md`;
- Act II: `LENS-2026-09-30-plaid-act-2.md`;
- the enhanced baseline, as a working draft: `operating-model-BASE-1.0.60.md`, a new record beside 1.0.51.
  **1.0.51 governs until he blesses it**;
- the new minimal model: `MODEL-2026-09-30-plain-rules-for-ai-help.md` and its card;
- the floor tools in `bin/`: `floor-selftest.sh`, with `README-floor-tools.md` at the root.

### A26 · 2026-08-29 · read-backs settled — **Q-2 and Q-8; slide 34 called**
Three answers, returned together as one signal.

**Q-2 — "Access Performance" is *access*, not *assess*.** So the loop page's mechanical
rail carries a **constraint, not an act**: only the measures you can actually reach count.
The stronger of the two readings, and it sits correctly above Tokens and Time — the two
measures that are *always* reachable and therefore always tempting.
**Carried by:** `NOTES-2026-08-28-lens-and-loop.md` **1.0.51**.

**Q-8 — "one end's view" is a READ, not a COUNT.** Way 2 governs; way 1 (fence `UF` as we
fence tokens) is not needed. **The padding exposure closes, and it closes properly rather
than by fiat:** buying more gauges does not raise a *read*, because comprehension is not
inventory. Probe A on the settled definition — volume up, value flat → `UF` unchanged →
`SP/UF` unchanged. **It passes.**
Two mechanical consequences, both already implemented: `face_kind` keeps its teeth — a row
declaring `count` still earns `[padding exposure LIVE]` from `bin/bearing.sh`, and that is
now a statement about *that row's instrument* rather than a doubt about the formula
(`B-SURFACE` is the honest live example) — and **`read` is the default**, with a row that
cannot say how much of its bearing is legible from one end obliged to declare `count` and
take the flag rather than round up.
**Carried by:** `RISK-CANON.md` **1.0.51**.

**Slide 34 called: `34@risk1.room1.land1`.** A volunteer's metric, agreed before the room ·
forty minutes, workshop · a second metric held in reserve. Legal under the declared
tensions. This is a **called shot about the talk**: the coordinate is the beat-1 guess, the
room is the actual, and the delta is the product. It is the first time the method has been
pointed at the deck that explains the method.
**Carried by:** this anchor. `SLIDES-catalogue.md` and his hand-edit file were **not**
touched — the selection is a record, not an edit to the grist.

**Regime note, because it decides whether anything was owed:** all three landed under the
**sidecar regime** (Part E — sha256, by design), not the signing regime. Sidecars refreshed
and verified for every file touched. **No pen was owed and none was taken.**

**Still open from the same set: Q-1** (what `[DR]` stands for — it sits between GUESS and
TEST, so it is likely the thing that carries the guess forward for TEST to settle, but that
is a guess at an initialism) **and Q-5** (whether the LENS left edge is the system side
end-to-end, plan → result). Q-5 is the one the rest of the readings lean on, and if it
comes back *no*, the `SP/UF` axis mapping needs rebuilding rather than adjusting.
**Status:** DONE for Q-2, Q-8, slide 34. **OPEN** for Q-1, Q-5.

### A25 · 2026-08-28 · credit — **two threads open, both blocking the credit line**
He showed 1.0.50 to Bryant and to Bridgit.
- **Bryant** — asked whether he wants any update to his credit. **No answer yet.** The
  current line names "Bryant Frankford and B.K. Graphics (bkgraphics.com)"; `AUTHORS.md`
  in modelthisbook also carries his site and email.
- **Bridgit** — **confirms she wants to be credited**, and is asking **what name to use**
  under any email, site, etc. **No name yet.**

**Status: OWED, BLOCKED.** The credit line is **not** amended with a placeholder — shipping
an incomplete credit is worse than adding one on her word, and the spelling is not mine to
pick: it appears as **Brigidt** in `CORWIN.md` §22 and `AUTHORS.md`, and as **Bridgit** in
his message. `AUTHORS.md` already holds the slot: "[co-author — pending confirmation]".
**Also standing, from CORWIN.md §22:** Bryant Frankford is a distinct person from her —
do not conflate. **Both answers land here, then the line and `AUTHORS.md` update together.**

### A24 · 2026-08-28 · fold the news/ material back — **1.0.51**
> "See if there are techniques or prose or otherwise thought that can be folded into what
> we have here, versioning to 1.0.51 as you do make updates here"

**Folded:** the three-law ordering (tools/tests second only to harm avoidance, hence
always-on drift); the reserved wind-down budget (17%, grace 9%) with drift's own floor
(≥9%) **taken after the other budgets so it does not skew them**; passthrough;
validate-then-regenerate; fold-to-the-extremes-and-strip-the-order as the case picker; the
pressure vocabulary (piles/boulders/mountains) as Part B2; and two of his sentences kept
whole — *the methods are offered, not forced* and *understanding hard things is creating
access.* **Carried by:** `operating-model-BASE.md` and `operating-model-CORWIN-ORG.md`, both
at **1.0.51**. **Status:** DONE.
*Evidence noted, not a change:* the Roll for Bias line already ran 1.0.50 → 1.0.60 → 1.0.90,
so the Emacs scheme (A15/A19) is house practice being written down, not a new convention.

### A23 · 2026-08-28 · clean up news/ and route it
> "write your version of a single cleaned up version of the general work for Book,
> building separate-cleaned up materials as separate markdown files where you see the best
> opportunities to maximize reuse, finally updating the README there to be a useful human
> intro, to direct you to your own principle semaphore … and place a NEWS-TOOLS-USAGE.md
> (or other better name you have) into F:\claude\modelthisbook"

**Carried by:** `news/MORNING-BOOK-MODEL.md` (the assembled model, his words preferred),
four `news/METHOD-*.md` files, `news/SMOOTHING-REVIEW.md`, `news/STORY-SEEDS.md`,
`news/README.md`, and `modelthisbook/METHODS-FROM-NEWS.md` (renamed from his suggestion —
"news tools" reads as tools about the news; his name is available on request).
**Principle semaphore proposed: `FANTASY-SIDE`** — creative latitude granted because other
systems are careful elsewhere; outputs are art or analysis, never operational directives;
lowered by Corwin **or on contact** with a real system, real user data, or an interface
control. **It is a CANDIDATE, not a convention** — `SEMAPHORES.md`'s own law is that an
unregistered signal is a candidate, and registering it is his.
**Not done on purpose:** the raw `README` (no extension) was **not** overwritten or renamed
— it is his unedited framing and the densest source in the folder; the new intro is
`README.md` beside it and points at it. Rename or replace on his word.
**Status:** DONE, with the semaphore registration open. — **SP/UF**, and the ordinal rule corrected
> "H x M = that's actually at the very bottom of the formula I have it as: SP/UF where UF
> is product of measured feeling and understand (mass weight of total bearing
> instrumentation with one ends view simply multiplied to make a last minute volume total
> approximation: this is a very me technique). Totally cool if my math isn't."

**Authorizes:** the bearing ratio **SP/UF** — Show × Plan-confidence over Understanding ×
Feel — and the **rung ladder** in which an ordinal product is rung 0, a confession rather
than a fallacy. **This corrects a rule of mine:** RISK-CANON had said "if the factors are
ordinal, say so and stop." That refused the whole ladder because of where it starts. The
refusal now applies only where an ordinal would stand as a *likelihood or a cost*.
**Carried by:** `RISK-CANON.md` §The bearing ratio, `bin/bearing.sh`,
`bearing-lab-teardown.tsv`, base model Part D. **Status:** FOLDED, tooled, 7 new selftest
cases green.
**My check on his math, since he invited it — Q-8:** `UF` is described in quantity terms
("mass weight of total bearing instrumentation"), and a quantity in a denominator makes
the ratio fall when you add gauges without understanding more — our own Probe A, failing
in the one place we would not have looked. It is sound if "one end's view" is a *read* of
what you can take in rather than a *count* of what is deployed. The tool now requires that
word to be declared and announces `[padding exposure LIVE]` when it is a count. **His to
answer.**

### A21 · 2026-08-28 · "simple cell" resolved
> "You had risk as a single field called risk: that's all I was getting at with 'simple
> cell'."

**Resolves** the open thread in A16: not an earlier model of mine to recover — the prior
representation was literally one field named `risk`. The multi-field row is its
elaboration. **Carried by:** `RISK-CANON.md` provenance note, rewritten rather than
deleted so the wrong guess stays visible. **Status:** CLOSED.

### A20 · 2026-08-28 · the method has a name — **CALLED SHOT**
> "Called shot is rad, let's ride that. Bless."

**Authorizes:** `CALLED SHOT` as the name of the whole method — the loop, the lens, the
measures, the risk canon, the bearing ratio. **LENS remains his word** for the four-point
figure. Coinage was mine, offered and blessed; alternates `Delta-Check` and `The Waist`
kept as contrast. **Carried by:** base model head + Part A, `operating-model-CORWIN-ORG.md`,
`SLIDES-catalogue.md`. **Status:** CANON.

### A19 · 2026-08-28 · mid-turn correction — **governs A15**
> "I see an error in that. Present version should v1.0.50 (not v2 lol)"

**Authorizes:** the present working version is **1.0.50**, not 2.0.50. Everything stamped
in this session carries 1.0.50. **Status:** LIVE. Newest comment governs; A15 stays as
record, unedited.

### A18 · 2026-08-28 · the lab, and what the teardown is for
Flat surface (David had no good table option; the **full** pair-note method cannot run
without one) and better cable bundling, pulled toward the nearest not-quite-connected
device or tower. Practical goal: the **Empyrean left side**. Hands: Bryan and maybe the
kids Saturday, Dee Sunday for the delicate bits, "all back full" for movies Sunday night.
**Moved, same message:** to the **three-day weekend**.
**Carried by:** `LAB-TEARDOWN-plan.md`, `risks-lab-teardown.tsv`. **Status:** LIVE.
Also recorded: pair note-taking, lite and full, taught by David Dyer-Bennet in his
apprentice sophomore year — the swap is the measurement.

### A17 · 2026-08-28 · measures, tags, and the volumetric proof
> "develop tools and tests and measure and tags and measure-tags-that-are-not-semantic-tags
> and use these to balance so we have some proofs all our measure are NOT volumetric or
> falling backing to something that is volumetric"

**Authorizes:** the measure/semantic tag wall, the two-probe guard, and the derived-input
closure check. **Carried by:** `MEASURES.md`, `measures.tsv`, `probes.tsv`,
`bin/measure-guard.sh`, `bin/selftest.sh`. **Status:** BUILT — the guard catches all
three planted failures and the selftest is 8/8. The construction is mine; the requirement
is his.

### A16 · 2026-08-28 · RISK — **binding canon**
> "we do not call it 'risk' unless it is measured. measured purports to be information
> (the word 'risk' once affixed veritably screams 'understand me' to the bearer)"

Two factors minimum: **OCCR_FCTR** (likelihood, percentile, most comprehensive defensible
formula, evidentiary receipting, detail not narrated in routine work unless it must be
surfaced) and **COST_BLST** (material+ cost graph; ≥1 materially noticeable expense
including time even when untracked; whole dollars or dollars/unit; may graduate to series,
series-of-series, pie as need calls).
**Carried by:** `RISK-CANON.md`, `bin/riskcell.sh`, `risks-lab-teardown.tsv`.
**Status:** CANON, tooled. **Open thread:** he referred to "the simple 'simple cell' risk
model you just presented"; I find no such cell of mine in this thread, so the cell in
`RISK-CANON.md` is marked **mine** rather than claimed back. If he means an earlier one,
it supersedes.

### A15 · 2026-08-28 · versioning — **superseded in part by A19**
Switch to his preferred Emacs-oriented nomenclature. As stated: the present materials
would be v2.0.50, moving toward **1.1.90** (a stand-alone delta for existing 1.0-based
models to consider adopting) or toward **2.0** (via 2.0.60/90 working steps), possibly
both via git branching. **Corrected the same day by A19: present is 1.0.50.**
**Carried by:** every file stamped this session; the version table in
`operating-model-BASE.md` Part F. **Status:** LIVE as corrected.

### A1 · 2026-08-28 · this session (chat)
> "make sure you have a clear understanding of what DID improve; ensure that you effect
> DRIFT etc. an incorporate more critical advancements; consider reviewing transcripts back
> a week or more" — and, on hub shape: **hub of pointers**.

**Authorizes:** this ledger; a hub `DRIFT.log`; the improvement record below; a transcript
sweep back ≥7 days. Explicitly **not** authorized: edits to any model file in t0/t1/t2.
**Carried by:** this file, `H:\ta/DRIFT.log`. **Status:** LIVE.

### A2 · 2026-08-25 · `F:\claude\C4-STEERING-2026-08-25-c-for-command.md`
His inline `[bless]` marks on `c/` for COMMAND, collision-as-localization ("**local reseed**"),
the "forgives forgetting prior cleverness" habit, and the backward-consing reading method.
**Carried by:** c4, lab-side. **Status:** LIVE but **RESERVED** — out of TA shipped content by
this project's own reservation rule. **Relevance here is the instrument, not the content:** the
steer→readings→bless→questions form is what this ledger adopts.

### A3 · 2026-08-25 · `t1/RULINGS-2026-08-25.md` V1
> "The v1.0 as built for FSF can be cannon governing all the work we do there, modulo
> Savannah will survey and in-take itself (or not, it's business, not ours here)."

**Authorizes:** `t1/operating-model-BASELINE.md` as canon for t1; the Savannah carve-out stands
verbatim. **Carried by:** t1 BASELINE + sidecar. **Status:** ACCEPTED.
**Tension (unresolved, T1/T2 below):** the accepted body is **v0.9**; t0 cut **1.0** the same
day. His word "the v1.0" and the artifact's actual v0.9 body do not agree — recorded, not
reconciled. *This is the ledger's second find.*

### A4 · 2026-08-25 · RULINGS, late-turn
> "Good story. Where do I sign?" · "Whatever blunter wording, I'm not sure I'm
> finding/remembering it from these clues."

**Authorizes:** SEED v0.3 → **v0.4**; §2.1 amended to claim only what the disk shows.
**Carried by:** `t1/operating-model-SEED.md` + sidecar. **Status:** ACCEPTED.

### A5 · 2026-08-25 · RULINGS, V5 clarification — **STANDING LAW**
> "I'm not going to edit some signed meeting notes because the next meeting changed… so that
> I can become more organized not more pedantic about ensuring each scrap of paper I have
> contains only accurate, current, relevant information."

**Authorizes:** supersede-by-new-record; never rewrite the signed past.
**Carried by:** t1 RULINGS; **the conflict rule at the head of this file**. **Status:** STANDING.

### A6 · 2026-08-25 · RULINGS, cadence catch
> "I upped my claim there; that's a good catch TBH. I'm okay with weekly but I'm glad to
> notice I did that."

**Authorizes:** weekly cadence by act; the named-escalation clause — a confirm instrument
carries no silent term-change. **Carried by:** `t1/front-door/comms/DRAFT-2026-08-25-ian-zoe-confirm.md`.
**Status:** LIVE, **BLOCKED** — permanent 5.0.0 bounce to `iank@fsf.org`; Ian unreached, Zoe
presumed delivered. Route is his pick.

### A7 · 2026-08-24 · `t0/PLAN-v0.9-to-1.0.md`, "Restated framing (Corwin)"
1.0 is a **draft for review**, not a public release; wider publish later adds sample models
built **with** the reflected people; GNU/FSF are a test subject only and nothing GNU/FSF-grounded
ships in the kit; **Bryant credit is strategic, not courtesy**; ceremony stays light to match a
draft. **Carried by:** t0 PLAN, PUBLISH-NOTES, LICENSE.md, the v1.0 tag.
**Status:** LIVE, partly **OPEN** — Bryant's business name + website still placeholders.

### A8 · 2026-08-24 · `t0/TEST-WATCH-NOTES.md`, Notes A–E — **the cleanest trace in the corpus**
Collected under his own instruction *"do NOT roll from this feedback yet — collect only."*
- **A** migration hand-back refinements ("lather rinse repeat")
- **B** a model-drift file and a literal-changes file, interlinked
- **C** lead with the user's own content/voice; don't bury the lead
- **D** license/copyright during churn; credit Bryant/Alfred
- **E** the head-matter is two things fused; split the anchor from the narrative

**Landed as:** the two 1.0 DIRECTED clauses (*state provenance when you derive*, *lead with the
host's own framing*), plus `CHANGES.md`, `MODEL-DRIFT.md`, `MIGRATION.md`.
**Carried by:** t0-kit v1.0. **Status:** LANDED.

### A9 · 2026-08-24 · session close-out (transcript `local_e8ef6800`) — **STANDING GUARD**
Recorded fault: the Bryant "deferral" was **invented and laundered as his**; check claims
against what he actually said. **Carried by:** memory + this row. Matches CORWIN §23
rail-laundering and PRINCIPLES clause 6. **Status:** STANDING.

### A10 · 2026-08-23 · the "gram of nine"
> "taken seriously → testable, somehow" — plus his worry that the opportunity framing was
> too narrow.

**Authorizes:** nine features across v0.6–v0.9, **each shipping a proof-pair**; EPMO as the
answer to the narrow-opportunity worry. **Carried by:** `t0/ROADMAP-GRAM-9.md`, the t0-kit
apparatus directories. **Status:** LANDED.

### A11 · 2026-08-23 · **RECOVERED FROM TRANSCRIPT — carried nowhere on disk**
From `local_5223b8e8` ("Empyrean operating model baseline"), his clarification turn, which the
session **aborted on an API error before any response**:
> "We have two baselines we can offer for git: (a) faster agent driven, (c) slower
> continuation command or run-card (per preference or using continuation command offering
> run-card the first time, as a baseline offering)"

**Would authorize:** a two-baseline git offering — agent-driven fast path vs. run-card/continuation
slow path, selected by preference, with the run-card offered first-time as the baseline.
**Carried by:** *nothing.* `t0-kit/git/git-drive.sh` implements only the fast path.
**Status:** **OPEN / UNANCHORED.** *This is the ledger's first find — a comment lost to an
aborted turn, not to disagreement.* (His own note in that same turn — "[edited, removed, false
'safeguards'…]" — is not reconstructed here; the transcript shows it snipped, and inventing it
would be the A9 fault.)

### A12 · 2026-08-23 · `t0/OPPORTUNITY-LIFT-SCAN.md`, "the default mood"
Opportunity-seeking toward the organized, shared office space is the **fallback disposition**
when nothing else says otherwise — named as eagerly as risk. **Carried by:** model v0.5 onward
(the "name it *as* an opportunity" clause). **Status:** LANDED.

### A13 · 2026-08-22 · licensing steer
Documentation and prose **CC BY 4.0**; source code **GPL-3.0-or-later**; Empyrean grant carried
at least until public git push. **Carried by:** t0 LICENSE.md/README, t1 front-matter.
**Status:** LANDED at t0 and t1; **UNSET at t2**; `H:\ta/.project.yml` still says
"unset by design" and is now stale against this anchor.

### A14 · 2026-08-20 · project initialization, open questions to him
Three questions were put and, so far as the disk shows, never answered: (1) is this project
truly context-isolated; (2) is **SAVANNAH v1.0** the authoritative principle source; (3) how
paranoid should the seam discipline be. **Carried by:** `H:\ta` memory note only.
**Status:** OPEN.

---

## What DID improve — the advancement record (evidence, not narrative)

Read with `t0-kit/CHANGES.md` (each delta) and `t0-kit/MODEL-DRIFT.md` (the direction).

**The through-line the drift record itself names:** *make the load-bearing explicit; keep
process-residue out.* Every version since v0.9 is one instance of that.

| Version | The advancement | The failure it fixes | Evidence it is real |
|---|---|---|---|
| v0.2–v0.5 | outside-in grounding; core behaviors; the C1/C2 claim with a negative control | ungrounded generic defaults | ablation run, reported as *data not proof* (single evaluator) |
| v0.6–v0.8 | *scale the proof to the stakes*; *account to value by deference, not by metric*; 13 apparatus pieces each with a positive probe **and** a negative control | untestable assertions ("taken seriously → testable", A10) | proof-pairs; `check-all` green; fail-closed `ship.sh` |
| **v0.9** | disclosure **split into two boundaries** — minimum-necessary at the *share* line vs **record by default** at the *operator's own record* line | the observed **silent drop**: unique data lost because "care" was under-specified | eclipse PASS on three seeded projects; the fold that scopes third-party/regulated data onto the same care path |
| **1.0** | **provenance anchor** (author · license · how to verify) + **lead with the host's own framing** | the observed **stall** (agent froze on authorship/license) and the **buried lead** (head-matter mushroom) | eclipse PASS; the rejected loser kept — "full author+license+credit block at the top" is the mushroom the fold defeats |
| 1.0 infra | `CHANGES.md` / `MODEL-DRIFT.md` / `MIGRATION.md` interlinked; adopt-by-content, verify-by-hash, keep-a-copy | version lineage read as a diary instead of credentials (Note B/E) | the v0.9 self-healing test **passed cold**: a fresh session adopted by content, provably reversible to `f672bb…`, and flagged an unsubstantiated over-reach rather than silently keeping it |

**The critical advancement to carry forward**, in one line: the model stopped asserting its own
trustworthiness and started shipping **checkable pairs** — a behavior plus the falsifier whose
contrapositive is the failure it prevents. That is the thing worth propagating into every
localization, and it is precisely what t1 and t2 do not yet have.

**Named but not built (kept as grist, per `MODEL-DRIFT.md`):** the full "show the résumé"
presentation; an `--expect` attestations file so the drift guard stops skipping; a
`methodclean-check` wired into `check-all` (the eclipse pass's #1 pre-drop hardening, and the
only caveat that is *not* self-stating).

---

## Tensions carried forward (mechanics · stressors · cost) — recorded, not smoothed

- **T1 · The baseline forked while it was being localized.** Lineage lives in digests, not
  branches. t1 localized v0.9 the day t0 cut 1.0; t2 came off an earlier cut still. Cost: the
  two clauses that fix the two *observed* failures are absent from both live instances.
  Re-localizing ≈ one session each, and for t1 it reopens A3.
- **T2 · Canon-acceptance vs. upstream currency.** His own change-management rule says the
  approved prior governs and a newer copy is a proposal. Forcing 1.0 in costs A3 its provenance;
  waiting leaves two known failure modes live in the instance touching real people.
- **T3 · Two ceremony regimes, both principled.** t0 signs and tags; t1/t2 are sidecar-only
  *because Part E claims no dependence on signing*. Merging them silently would falsify a
  shipped claim. Cost of keeping both: every report must say which regime it is quoting.
- **T4 · License non-uniformity with a consent edge.** t2 is UNSET **and** names third parties
  (partners in the model text; volunteers in `volunteer-tracker.csv`). PRINCIPLES clause 5 and
  CORWIN §33 both bite here: multi-party consent needs all parties visibly diligent. Cheap to
  clear by asking; expensive to skip.
- **T5 · The comment chain was uninstrumented** — this file is the first pass at closing it, and
  it immediately surfaced A11 (lost to an aborted turn) and the A3 v1.0/v0.9 wording gap.
- **T6 · The non-expert-operator claim is asserted, not measured.** Every validating run was a
  cold model session. `t1/negative-control/` is the apparatus and has been idle since 08-23.

---

## Openings (the guard's other half)

- The kit is CC BY 4.0 and method-clean **now** — it can ship as free documentation, which
  broadens others' freedom, not only the operator's.
- Two live localizations off one baseline are exactly the "sample models built *with* the
  reflected people" that A7's wider-publish plan says it needs — t2 is that, once consent is
  visible.
- The `C4-STEERING` instrument has now found its second customer (this ledger). By the
  two-recurrences rule that is a tool asking to be forged — and unlike its content, the *form*
  carries no reserved vocabulary.

---

## Verdicts — UNSET (his)

0. ~~The method's name~~ — **SETTLED: Called Shot** (A20).
0b. The **read-backs** in `NOTES-2026-08-28-lens-and-loop.md` — Q-1 through Q-7, chiefly
   what `[DR]` stands for and whether the left side of the lens is the system side
   end-to-end. Plus **Q-8** (A22): is "one end's view" a read or a count?
0c. **Direction** — 1.1.90 (delta back to 1.0-based models), 2.0.60→2.0.90, or both on
   branches. Not guessable yet by design; the version table waits on features or patches.
0d. **Credit (A25)** — Bryant's answer on any update he wants; **Bridgit's chosen name and
   its spelling** (Brigidt / Bridgit both appear in the record, and it is hers to say).
   The credit line and `AUTHORS.md` update together once both land.
0e. **`FANTASY-SIDE`** — register it in `F:\claude\SEMAPHORES.md`, amend it, or reject it.
   Candidate until you do, by that registry's own law.
0f. **`news/README`** — leave the raw file as-is beside the new `README.md`, rename it to
   something like `SOURCE-corwin-framing.md`, or fold it in. I did not touch it.

1. Adopt this ledger as the hub's instrument, or amend the form first.
2. **A11** — is the two-baseline git offering still wanted, and does it belong in the kit or
   in c4?
3. **A3** — does "the v1.0 as built for FSF" mean the v0.9 body he accepted, or 1.0? A record,
   not an edit, either way.
4. **T4** — t2's license, and whether the named partners/volunteers have seen the document.
5. **A14** — the three 2026-08-20 questions, still open.
6. **A7** — Bryant's business name and website.

---

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
