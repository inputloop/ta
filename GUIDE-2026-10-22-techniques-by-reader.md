<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Techniques by reader: an organization's AI kit, for helpers strong and weak

Corwin Brust · 2026-10-22 · CC BY 4.0 · check the evidence: `exp-2026-10-22-floor-ladder/` (`sh check.sh --prove-red`, then `sh check.sh score cases.jsonl results.jsonl`)

## What this is

The offering is a small kit an organization drops into any AI session, so the AI grounds itself in that
organization's public identity and prefers the organization's own written rules over the kit's wording.
This guide gathers what the work of the last three weeks taught about making that kit hold up when the
AI on the other end is strong or weak, has tools or has none. Every technique below says what to do,
how it changes by reader, and what would show it wrong. Where a technique rests on a run, the run is
named; where it rests on judgement, it says so.

## The readers

| reader | what it is | give it | ask of it | keep from it |
|---|---|---|---|---|
| **Paste-only** | any chat with no files and no tools | one file, pasted whole: the floor and the organization's quoted rules | judge one thing at a time against one named rule | anything it would have to remember between turns |
| **Small local** | a model of about 4 to 12 billion parameters on the organization's own machine | a narrow slice and a fixed answer form | first reading, extraction, claim-by-claim checks | final verdicts that let work through |
| **Capable, no tools** | a large hosted model in plain chat | the full rules with their reasons | judgement, drafting, a second reading | claims about files or runs it cannot see |
| **Agentic** | a model that can run commands and read files | the rules, the checks as programs, and the record | run the checks, keep the record, prepare decisions | the decisions that belong to a named person |

One kit serves all four. The floor is the same text everywhere; what changes is how much is put in
front of the reader and who makes the final call.

## Twelve techniques

**1. Three answers, and count the false passes.** Every check answers OK, RED, or NOT CHECKED (it could
not look). The number that matters is how often a fault, or a record nobody could look at, was called
OK. An error toward RED or NOT CHECKED sends work to a person; an error toward OK lets it through.
*By reader:* the same for all. *Evidence:* in the floor-ladder run, every step of help lowered false
passes on every reader (the smallest went from 6 to 1 in 17). *Wrong if* a rerun shows false passes
rising when rules are added.

**2. For a small model, split the verdict and let code decide.** Ask two yes/no questions: is what you
would need to look at shown, and is the rule met? Code turns the two answers into the verdict. *By
reader:* small local, essential; paste-only, useful when a person reads the two answers; capable and
agentic, not needed. *Evidence:* qwen3:8b went from 10–11 of 17 to 14 of 17; gemma4:12b did not
improve, because it reads a missing record as a broken rule. *Wrong if* the split fails on a second
small model of another family.

**3. Say what a missing record means.** Some organizations want a missing record treated as a fault
(fail closed); others want it named as not looked at. Small models pick one silently and differ from
each other. The kit states the organization's choice, and the default is NOT CHECKED, which is never
written down as OK. *Wrong if* an organization's auditors read NOT CHECKED as a pass in practice.

**4. The organization's own rules are the active ingredient.** Strong readers already bring general good
sense; what the kit adds is the host's particular canon. Quote the organization's rule; do not retell
it. *Evidence:* two hosted readers scored 16 of 17 with no rules at all; the one case they missed was
the rule peculiar to the house, and with the rules in front of them they got it. A separate run found
that a grounding packet, not a persona, moved a model's choices. *Wrong if* a harder case set shows
hosted readers missing generic cases without rules.

**5. Plants by someone else.** A check's author plants faults the check was built to catch. Have
someone who did not write the check plant the faults. *Evidence:* authors' own plants were all caught;
others' were caught 1 time in 55. *By reader:* agentic readers can run planted tests; for the others, a
person or a second model plants. *Wrong if* a planned rerun with outside plants shows the gap under 15
points.

**6. Call the shot.** Write the guess, with what would show it wrong, before the run, and seal it with a
fingerprint (a SHA-256 of the file). Settle the result against it, including the parts that missed.
*By reader:* any reader can be asked to state its guess first; agentic readers can seal it. *Evidence:*
of this guide's own run's nine predictions, three failed outright and three held only in part,
and those misses are what taught techniques 2, 3 and 4.

**7. Two readers, two languages.** A check is re-derived by a second program in a different language,
and the two must agree. A second reader who copies the first reader's numbers is one reader twice.
*Evidence:* the run's scorer (awk) and re-deriver (Perl) disagreed on their first trial, over whether a
blank first line counts; the disagreement was found by the planted test, not by reading the code.

**8. Match the reader to the role and the slice.** Small models are good first readers and
claim-by-claim checkers and poor final judges: they round "partly" down to "no", or imitate a verdict
they were shown. Give a small model a narrow slice and an exhaustive task; give a large model the whole
and a judgement. *Wrong if* paired runs show the larger model finding more valid items in exhaustive
checking (one earlier pair, small against mid-size, found the small one ahead).

**9. A gauge, not a guard; use the host's tool when it is there.** Prefer controls that show state and
let a person decide. Where the organization already has a tool for a job, the kit hands the job to it;
where it does not, the kit runs its own portable half and says which it did.

**10. Keep the record by adding, and write each fact at the act.** Records change only by a new record
beside the old; who did what, with which AI (maker, model, date) and who reviewed it, is written when it
happens by the hand that knows it, never read back later from a settings file.

**11. Off means absent.** A part of the kit that is switched off contributes nothing to the session: not
a line saying it is disabled, not its rules in the context. Every ceremony the kit adds has an off and
an automatic setting, and both are tested.

**12. Plain words, checkable by hand.** Every rule and its check are short enough to read aloud and in
the language of the people they affect. *By reader:* this is what makes the paste-only reader possible.

## Open spaces

- **A harder case set.** Hosted readers are at the ceiling of the current 17 cases; a second planter
  and harder cases are needed to measure anything above the local readers.
- **The missing-record policy as a declared field** (technique 3), with a test that a reader follows it.
- **Paired runs for exhaustive checking**, one brief to a small and a large model, to settle technique 8.
- **The organization in the room.** No run yet has had a real organization's owner of its rules taking
  part; that remains the central claim's untested precondition.
- **Where the organization's rule meets the person's ask.** Whether the user's own prompt or the
  organization's written rule wins, when they meet, is for the kit's keeper to rule; the kit records each
  meeting meanwhile.

## Credit

Developed and tested with the help of Bryant Frankford (bryantfrankford.com), with thanks; the small-model
discipline in technique 2 extends rules from his Llama Bridge manual.
