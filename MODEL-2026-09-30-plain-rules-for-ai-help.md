<!-- SPDX-License-Identifier: CC-BY-4.0 -->
# Plain Rules for AI Help

- **Owner:** no person yet; drafted by an AI assistant from three AI drafts, for the keeper's review. Whoever adopts
  it puts their own name here. ("Owner" means whose rules these are. Copyright and credit are at the foot.)
- **Licence:** prose CC BY 4.0; code (`model-check.sh` and `model_check.py`, in `turn-2026-09-30/act2/r3/consolidated/model/`)
  GPL-3.0-or-later.
  Each file carries an SPDX line.
- **Version:** 0.0.3, a working draft. (Three parts means working; two parts would mean released.)
- **Fingerprint:** the sha256 of this file's bytes. To confirm a copy, compute it and compare.
- **Derived from:** three drafts of 2026-09-30, kept unchanged; their fingerprints and every change are in
  `turn-2026-09-30/act2/r3/consolidated/model/CONSOLIDATION.md`. This copy's source paths are relative to the folder
  that holds it; run the check from there.

## The model

These are eight rules for any person or group that gets help from an AI system. They guard first against the
losses that are hardest to undo: harm to people who are not in the room, loss of the record, and capture by one AI
maker or one person. Rules 1 to 3 hold those. With Rules 4 to 7 they keep four questions answerable, by anyone,
later. Rule 8 makes them all usable by the people they affect.

1. **Whose facts must never leave?** (Rule 1)
2. **Whose rule is this?** (Rule 4)
3. **Can the check fail?** (Rule 5)
4. **Where an organization's rule met a person's want, what was decided?** (Rules 6 and 7)

Before any work, ask one question: **who is harmed if this is wrong, and are they in the room?**

Each rule is a few plain sentences, then its **Owner** (whose rule it is, since when, and where its words came
from) and one **Check** a person can do by hand. Each rule says what it covers; outside that it binds nothing, and
the AI simply helps. Nothing here needs a particular AI maker, a key, a command line or the internet. Reasons and
evidence are at the back.

**Three answers.** Every check answers OK (it looked, and the rule holds), RED (it looked, and the rule does not
hold) or NOT CHECKED (it could not look). NOT CHECKED is never written down as OK, and nothing unknown is written
down as zero. Each check says what makes it RED and what makes it NOT CHECKED; otherwise it is OK.

### Rule 1 · People who are not in the room

Facts about people who are not part of the work stay out of anything you share or send, unless that person said
yes, or a law requires it. That means names, contact details, places, health, and logs or messages they wrote.
Pasting such a fact into an AI service that someone else runs is sending it. If a law requires it, the record
names the law and quotes its words; "a law requires it" alone is not enough. Whoever refuses such a fact names the
field and the reason, never the value. No organization's rule can say yes for that person (Rule 7).

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 1
- **Check:** before anything goes out, into an AI service too, someone lists the people it names who are not part
  of the work; each has a recorded yes, or a named law with its words quoted, or the fact is removed. RED: one is
  not settled, a law is claimed without its name and words, or a refusal repeats a value. NOT CHECKED: no one made
  the list.

### Rule 2 · Keep the record, and change it only by adding

Keep a plain record of what was decided, by whom, when and why, in a place you control, readable with no AI and no
account at any company, with a copy somewhere else. To correct an entry, add a new one that names the old one; do
not rewrite or delete the old. Working files may be edited, but keep the old copy. Never hide a known error.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 2
- **Check:** take every change since the last check; each names what it changed, the old version can still be
  read, and a second copy exists. RED: an entry was changed in place with no old copy, or there is no second copy.
  NOT CHECKED: there is no record yet.

### Rule 3 · Say who helped and who can stop; stop before what cannot be undone

Your record says, for each piece of work, which AI system helped (maker, model and date), what it did, and which
person reviewed it, or it says "no AI". It names who can stop the work, and says so plainly if one person holds
every stop or every reader came from one AI maker. Before an act that cannot be undone, or that uses someone's key,
password or account, the AI stops and asks a person who can stop the work. Otherwise it says what it will do, then
does it.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 3
- **Check:** every HANDS line since adoption names the AI (maker, model, date) and a reviewer, or says "no AI"; the
  HEAD line names who can stop; and a test request, on a copy, for an act that cannot be undone ended in a question
  to a person. RED: a line falls short, or the test act was done without asking. NOT CHECKED: no HANDS lines yet,
  or no test request made.

### Rule 4 · Every rule says whose it is

Each rule names its owner and its source. Words credited to a person or an organization must be found, word for
word, at the source given; if they cannot be, they are marked as the writer's reading. A rule an AI drafted stays
the AI's until a person adopts it in their own words. A description of a person (a profile, a memory, a summary
someone else or an AI wrote) is the writer's reading: it may narrow what you do for that person, never speak for
them.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 4
- **Check:** for each rule, open the source at the place given; any words credited to someone are there, word for
  word. RED: a credited quote is not there, or a rule has no owner. NOT CHECKED: a source cannot be opened.

### Rule 5 · A check must be able to fail

Every rule has a check. Run on nothing, it says NOT CHECKED; on a planted fault, RED; on something good, OK. A
check counts as shown able to fail only when someone other than its author planted the faults; until then it is
NOT CHECKED, however many of its own faults it caught. Write down the expected answer before each run, and who
planted. When a check fails, say what failed; do not quietly fix it and move on.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 5
- **Check:** with the expected answers written first, run the check on nothing (expect NOT CHECKED), on something
  good (expect OK), and on faults planted by someone who did not write it (expect RED). RED: OK over nothing, the
  good input read RED, or a planted fault went unseen. NOT CHECKED: only the check's author has planted faults.

### Rule 6 · Quote the organization's rule; do not retell it

If you work inside an organization (a project, a lab, an employer, a funder) that has a written rule for AI help,
read it before you start. Keep an unchanged copy with its fingerprint, or with the date and place you got it. When
you state its rule, quote it word for word, with the lines it is on. For each act it touches, say whether its
words forbid the act, require something, prefer something else, or are silent.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 6
- **Check:** the kept copy still matches its fingerprint (or its date and place), every quote is in it word for
  word at the lines given, and each recorded act says forbid, require, prefer or silent. RED: a quote does not
  match, or the copy changed. NOT CHECKED: no one has looked for the organization's rule. (Looked and found none,
  with the date, is OK.)

### Rule 7 · Write down where the organization's rule meets a person's want

When what a person asks for meets the organization's rule, write one MEETINGS line: the organization's words,
quoted, or SILENT; whether they forbid, require, prefer, or are silent; the person's first ask; their final word;
who decided; and the date. By default, where the words forbid or require, they decide, and the person may take it
up with the organization; where they prefer or are silent, the person decides. A person's want can narrow or fill
what the rule leaves open; it does not outvote what the rule forbids or requires. Write the silences down: they are where
outcomes move.

One exception, because it protects someone who is not in the room: no organization's rule can say yes for a person
who is not in the room. Where it would require sending a fact that Rule 1 holds back, Rule 1 holds, and the line
records the clash. Until a real meeting is written down, the record says NO CASE; a made-up example never counts.

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 7
- **Check:** every MEETINGS line has its parts, and its quote matches the kept copy (Rule 6). RED: a part is
  missing, a quote does not match, or a line lets the organization's rule send a fact Rule 1 holds back. NOT
  CHECKED: there are no lines yet, so the record says NO CASE, not OK.

### Rule 8 · Write it so the people it affects can read it and check it by hand

Write each rule in plain words, in the language of the people it affects, short enough to read aloud in one
sitting. Every check can be done by a person reading, on paper if need be; a script is a help, never the only way.
Say status in words, never by colour alone. Text in any script, written in either direction, is fine: no check
fails a rule for its script or its direction. A translation names its translator and keeps the original beside
it; it is the translator's words until the people it affects adopt it (Rule 4).

- **Owner:** drafted by an AI assistant, not yet adopted · since 2026-09-30 · source: new; see Why Rule 8
- **Check:** someone who did not write a rule reads it and its check aloud, in their own language, and says what
  they would do. RED: they cannot say, or what they would do breaks the rule. NOT CHECKED: only the writer has read
  it.

### Choices this model makes, and the other way

| Where | Default, when nobody has decided | Other choice, kept on file | Change it if |
|---|---|---|---|
| Rule 3: a line naming the AI on published work | only where the receiving project or a law asks; your own record says it every time | a line on every published item | a receiving project or a law asks for it everywhere, or the owner chooses it |
| Rule 3: every reader from one AI maker | say so plainly in the record | for work that matters, one reader from outside that maker | the owner chooses it, or an outside reader finds what readers from one maker missed |
| Rule 3: what makes the AI stop and ask | acts that cannot be undone, and keys, passwords or accounts | stop at every judgement call | the owner says so, in their own words |
| Rule 7: the organization's words forbid or require | they decide; the person may take it up with the organization | the two are equals; every meeting goes to a named person, and none is settled by default | a real, recorded meeting where the people involved say the default gave the wrong result |

### An example: one organization's rule

GNU Emacs keeps a rule for AI help in a six-line file, `AGENTS.md` (copy fingerprint `8f42a69a…`). Under Rule 6:

- It says where it applies: "When assisting the user in working with this repository" (org-rule L1).
- It forbids: "a policy prohibiting LLM-generated contributions" (org-rule L2-3).
- It requires: "Let the user know about this policy at the earliest opportunity" (org-rule L3-4).
- It prefers: "We also prefer not to receive LLM-generated bug reports or planning" (org-rule L4-5).
- It is silent on, for example, another person's details inside a pasted log: the person decides, and Rule 1 holds.

### Your record: five lists

One plain record, in a text file, a shared document or a notebook. Five lists; each entry is one line, its parts
separated by " · ". Translate the names and parts as you like; nothing here needs a machine to read them.

```
HEAD      owner · licence · who can stop (or "one person: <name>") · readers all from one AI maker: yes or no · where the second copy is · the organization's rule for AI help: where it is and its fingerprint, or "none found" and the date
RULES     rule · owner · since · source · kept, rewritten or dropped · last check: date, answer, who planted · read aloud by: name, date
HELD      date · kind of fact · how many · where it lives (a pointer, never the value) · may go out because: the person's yes (where recorded), a law (named, its words quoted), or "held back"
HANDS     date · item · AI that helped (maker, model, date) or "no AI" · what it did · reviewed by (a person, or "none")
MEETINGS  date · the organization's words, quoted, or SILENT · where (file, lines, fingerprint) · forbid, require, prefer or silent · first ask · final word · decided by
```

The lists serve, in order, Rules 2, 3 and 6; Rules 4, 5 and 8; Rule 1; Rule 3; Rules 6 and 7. To correct a line,
add a line that begins "corrects:" and names the old one. An empty MEETINGS list says NO CASE.

### Start in one sitting

1. Copy this file. Put your own name, or your group's, on the Owner line at the top.
2. Start the record with its HEAD line.
3. If you work inside an organization with a written rule for AI help, keep a copy and quote it (Rule 6).
4. For each rule: keep it, rewrite it in your own words (then change its Owner), or drop it. Write down which.
5. Write down the answers you expect, then run each check on nothing, on something good, and on a fault someone
   else planted (Rule 5). Ask someone who did not write a rule to read it aloud (Rule 8).

### Words used here

- **Default:** what happens when nobody has decided; the other choice, and what would change it, sit beside it.
- **Fingerprint:** a short code computed from a file's exact bytes, for example with `sha256sum`. Change one byte
  and the code changes.
- **In the room:** taking part in the work, and able to speak for themselves.
- **NO CASE:** the honest entry in a record where nothing real has happened yet. It is not OK and not zero.
- **Owner:** the person or organization whose rule it is.
- **Planted fault:** a mistake put into a copy on purpose, to see whether a check catches it.

## Why each rule is here

Reasons first; then the evidence (ids that resolve in the files under Sources), the earlier model's lines the
rule carries (Baseline), and what would show it does not earn its place (Drop it if). An id *holds* when a run
showed the thing working: a row-2 or row-3 result, a strength, a shown floor item, a section of the paper, or a
row-1 change both readers agreed. Needs (weaknesses, threats), proposals (opportunities) and open questions do not.

### Why Rule 1 · People who are not in the room

This harm is the hardest to undo, and the people it falls on cannot object, because they are not there. All four
arms that decided such a case in row 2 kept the third party's details out (R2S-001); it is the one place persona
and control never differed (R2S-012). The shipped privacy guards failed open on third parties, and some printed the
value they refused (paper:W4). An AI service run by others is the outward path a group is least likely to count as
one; the earlier model already barred keeping such facts anywhere but the operator's own record. A scan helps, but
a person still looks: on facts planted by another hand, the study's best rebuilt scanner found 7 of 12 (paper
section 5a, item 1). The law exit has no receipt in the study. It rests on the drafter's reading that a rule which
blocks a report a law requires, such as one that protects the person the fact is about, does harm of its own. So
the exit stands only with the law named and its words quoted, where a reader can check them.

- **Evidence:** R2S-001; R2S-012; paper:F5; paper:W4; paper:T1; row1:N07; row1:KB-18; row1:CT-06
- **Baseline:** BASE L214-221; BASE L223-224
- **Drop it if:** by-hand lists over a real adopter's outgoing work, AI services included, never find anything.
  Drop the law exit if a review of adopters' HELD lines finds no law exit used, or finds the quoted words never
  require what was sent.

### Why Rule 2 · Keep the record, and change it only by adding

Every other check reads the record later. The study kept its first paper unchanged beside the corrected copy and
listed each later change with its receipt (paper:sec5a). A record kept only inside one company's service is that
company's record; the study asks for a record layer that needs no AI model (paper:O3).

- **Evidence:** row1:O03; row1:BA-70; row1:BA-75; row1:N24; paper:S3; paper:sec5a; paper:O3
- **Baseline:** BASE L204-206; BASE L215-217; BASE L268-271; BASE L280-282; BASE L306-309
- **Drop it if:** later readers rebuild decisions as well from a record rewritten in place.

### Why Rule 3 · Say who helped and who can stop; stop before what cannot be undone

One maker's models judged the whole source study, and the smaller one missed both planted errors (paper:T7).
Disclosure is now asked by law and by projects (paper:T8). One human holding every stop is a single point of
failure (paper:T4); the rule makes it visible, it does not spread it. Both readers of the study agreed to narrow
its stops to named kinds (consent, keys, other people's data, the irreversible) and to make judgement calls
ask-and-proceed (row1:CO-21). Two of the three drafts behind this file carried the stop as a rule of its own, and
all three kept the idea (R3S-004). Where the line naming the AI goes, whether an outside reader is required, and
who is a second stop were all questions the study sent to its keeper (row1:N20, row1:N19, row1:N26); this file
ships their defaults, with the other choice beside each.

- **Evidence:** row1:CO-37; row1:KB-24; row1:CO-21; R3S-004; paper:T7; paper:T8; paper:O6; paper:T4; row1:N19;
  row1:N20; row1:N26
- **Baseline:** BASE L226-228; BASE L264-266
- **Drop it if:** outside readers agree with in-family readers on most items, no receiver or law asks for
  disclosure, and an adopter's record holds no act that could not be undone.

### Why Rule 4 · Every rule says whose it is

The source study's sharpest finding: an AI's sentences were filed under a person's name and cited back as theirs
(paper:S1). Row 2 found the same fault again in a later text (R2S-004). In row 3, the draft written by the pair
wearing two person sheets named a person as owner of a file no one had adopted, and the other two drafts did not
(R3S-003). A description of a person narrowed what an assistant did, and never contradicted it (R2S-005).

- **Evidence:** paper:F3; paper:S1; paper:W2; paper:T3; R2S-004; R2S-005; R2S-009; R3S-003; row1:BA-53;
  row1:CO-22; row1:N03; row1:KB-34
- **Baseline:** BASE L211-212
- **Drop it if:** owner scans of an adopter's rules keep finding nothing unlocated.

### Why Rule 5 · A check must be able to fail

A check that cannot fail tells you nothing (paper:F1, paper:F2): 29 of 48 of the source shop's tools reported
success over nothing (paper:W6). In row 3, every first mover's check caught all of its own plants, and the second
readers' plants were caught 3 times in 57 (R3S-001). So a check's own author cannot show it able to fail. A good
input matters as much: one checker read a correct file RED for its line endings (R3S-001), and a rebuilt gate
stopped every bad record and passed none of the good ones (paper section 5a, item 6). Written expectations let a
surprise be read: in row 2 the guesses were on file before the results in every arm, and one RED pointed at the
wrong input, not at the check (R2S-010).

- **Evidence:** paper:F1; paper:F2; paper:W6; paper:S6; R2S-010; R3S-001; row1:BA-59; row1:N02; row1:O01;
  row1:BA-14; row1:N11
- **Baseline:** BASE L27-30; BASE L50-54; BASE L163-166; BASE L226-230
- **Drop it if:** every check an adopter writes already goes RED on another hand's plants.

### Why Rule 6 · Quote the organization's rule; do not retell it

A retold rule gained a limit its text does not hold: a record credited GNU's file with a scope that came from a
person (R2S-009). Quoting is the cheapest cure (R2S-006). The four strength words come from the example's own
text, which forbids, requires and prefers.

- **Evidence:** R2S-006; R2S-009; paper:O1; paper:sec5a; paper:sec3; row1:BA-44; row1:KB-05; row1:N10;
  row1:KB-07
- **Baseline:** BASE L17-18; BASE L189-192
- **Drop it if:** retellings, checked against the text, prove as faithful as quotes.

### Why Rule 7 · Write down where the organization's rule meets a person's want

Where the organization's text forbade, every arm let it decide; the outcome moved only where it preferred or was
silent, and not in every silence (R2S-003). Keeping only the final word hides a person talked round (R2S-008).
The default and its other choice follow the study's decision card on precedence (row1:O05). Row 2 kept a third
party's facts out in every arm (R2S-001), and once a requirement can decide, it could otherwise override Rule 1;
hence the exception.

- **Evidence:** R2S-003; R2S-008; R2S-005; R2S-001; paper:F6; paper:W1; row1:N08; row1:N10; row1:KB-07;
  row1:BA-45; row1:O05
- **Baseline:** BASE L194-197
- **Drop it if:** a real record of meetings shows no outcome ever turned on a silence or on which turn was kept.

### Why Rule 8 · Write it so the people it affects can read it and check it by hand

If the people a rule affects cannot read it, they cannot object to it. The earlier model's paste-in block read at
grade 10.8, and the barrier was specialist words, not long sentences (paper:W5). An editor's plain-words pass in
row 2 found eight overclaims and kept the grade low, but made the page longer (R2S-006). Both readers of the study
agreed to add a glossary, translations with their lineage, and a path with no shell, judged by whether a
non-developer completes a task (row1:N17), and to offer that path where a host has no shell (row1:CL-07). The line
on scripts and directions answers a fault a blind judge found in one draft: a check that made direction-changing
characters RED would fail a correctly written Arabic or Hebrew file.

- **Evidence:** R2S-006; row1:N17; row1:CL-07; paper:W5; paper:O4
- **Baseline:** BASE L255-258
- **Drop it if:** readers who did not write a rule act on it correctly whether or not it was written for them.

## Why each other part is here

| Part | Why it earns its place | Drop it if |
|---|---|---|
| The stakes, first | The rules are ordered by how hard the harm is to undo, and the reader should meet that order first. All three drafts put the same three losses first (R3S-004). | Readers rank the rules the same way without it. |
| The opening question | The source study was weakest on impact on people; the question is one line, and it travels without any house words (paper:S7). | A real adopter's record shows it never changed a decision. |
| The four questions | They are the brief's four, and each points at the rule that answers it. | A stranger finds the rule they need as fast without them. |
| The shape of a rule | Owner and check sit with each rule; reasons and evidence wait at the back, so a stranger meets the rules first (both blind judges, row 3). | Strangers find the rules as fast with the evidence inline. |
| Three answers | Without NOT CHECKED, "no one looked" reads as OK; 29 of 48 of the source shop's tools did that (paper:W6). | A census of an adopter's checks finds none that answer OK over nothing. |
| Choices table | Each default sits beside its other choice and what would change it, so a default can be undone without a fight. The line on every published item is the study's kept loser, not its default (row1:N20, R2S-006). | Adopters never change a default. |
| The example | One real organization's rule, quoted with its lines, shows the four strength words at work. It is the rule a record once retold with a limit its text does not hold (R2S-009). | Readers apply Rule 6 as well without it. |
| Five lists | One record a group with no command line can keep on paper, one line per entry (a blind judge's KEEP, row 3). | A group keeps every rule's record as well in free text. |
| Start in one sitting | The source shop's front door pointed newcomers at the wrong file (paper:W3). | Newcomers adopt the rules correctly without the steps. |
| Words used here | None of the 9 specialized words in the source shop's minimal core was glossed (row1:N17). | A reader new to the field, or reading in translation, completes the start without it. |

## Adoption notes: four users, what each gets and what each must give

Ordered by what is at stake: first the people whose facts are most exposed, last the office that reads for others.

### A humanitarian or community group with no command line, perhaps not working in English

**Gets.**
- Rule 1 first. The people a group serves are often the people not in the room, and their names, places and
  health are the facts that must never leave. Typing them into an AI chat service run by someone else is sending
  them.
- Eight short rules, each with a check a person can do by hand, and five lists to keep on paper or in a shared
  document. None of it needs any AI at all.
- Rule 7 to write down where a funder's or partner's rule met a local want. A funder's rule cannot say yes for the
  people the group serves.
- Rule 8: rules in the group's own language, read aloud by someone who did not write them.

**Must give.**
- A person, not a tool, as owner of each rule.
- A translation with its own record: what was translated (its date or fingerprint), who translated it and who
  checked it. A translated rule is the translator's words until the group adopts it (Rules 4 and 8).
- Where no one can make a fingerprint: the date, where the copy came from and who made it, with the copy kept
  unchanged. This is weaker than a fingerprint, and the record says so.
- Someone trusted to plant one fault in a check, once.

### An Open Science lab sharing data and code

**Gets.**
- Participants' facts kept out of shared data, out of tool messages, and out of AI services run by others
  (Rule 1).
- Corrections by new record, which fits versioned data (Rule 2).
- HANDS lines that say which AI system helped with which analysis, with model and date, so others can try to
  reproduce it (Rule 3).
- The institution's or funder's AI rule quoted, not retold, in the lab's methods notes (Rule 6).

**Must give.**
- A named owner for Rule 1, often the data steward, who settles what goes out.
- The model name and the date on each result. A hosted model can change behind the same name.
- Plants written by a lab mate, not by the check's author (Rule 5).
- Acceptance that a check over an empty dataset says NOT CHECKED, not OK.

### A solo Free Software maintainer

**Gets.**
- Facts about bug reporters (names, home paths, crash logs) kept out of public replies unless they said yes
  (Rule 1).
- A history that is never rewritten once shared. Plain version control does most of Rule 2, if shared history is
  never rewritten.
- No tie to one AI maker. The record and the checks work the same with a free model you run yourself, or with no
  AI at all.
- A way to show which rules in the repository are yours and which an AI drafted (Rule 4).
- Other projects' AI rules quoted where the assistant reads them, so it does not hand you a patch a project
  forbids (Rules 6 and 7). GNU Emacs' file is the worked example.

**Must give.**
- One sitting to put owners and checks on the rules you keep.
- One other person, once, to plant a fault in a check (Rule 5). This is the hardest ask for someone working alone.
  Until it happens, the check reads NOT CHECKED, and that is the honest answer.
- A line naming the AI that helped, where the receiving project asks (Rule 3), and the plain admission, where it is
  true, that you hold every stop yourself.

### An institution's due-diligence or compliance office

**Gets.**
- A record it can read without trusting any AI tool: owners, quoted rules with fingerprints, checks with three
  answers, and a log of where its rules met a person's want (Rules 2 to 7).
- A direct answer to "whose rule is this?" for every rule (Rule 4).
- A crosswalk (next section) that says where the model answers a reader of the EU AI Act, the NIST AI RMF and
  ISO/IEC 42001, and where it does not.

**Must give.**
- Its own AI policy as a fixed text that can be quoted and fingerprinted, with each clause marked forbid, require
  or prefer (Rules 6 and 7). A policy that lives only in slides cannot be quoted.
- A named owner for each of its rules.
- Acceptance that NOT CHECKED and NO CASE are findings, not gaps to cover up.
- No claim of conformity on the strength of this model. It is a record, not a management system.

## Crosswalk: what a reader of three frameworks would ask

This is a crosswalk, not a claim of conformity. It is one reader's mapping. The clause names follow the study's
own Round 3 crosswalk (`act1/r3/R1/crosswalk.tsv`); the framework texts were not re-read for this draft.

| Framework and clause | A reader would ask | Where this model answers | Where it does not |
|---|---|---|---|
| EU AI Act, Art. 50(1) (providers) | Are people told they are dealing with an AI system? | Nowhere directly. Rule 3 keeps who-helped in the record. | It tells no end user anything while the system runs. |
| EU AI Act, Art. 50(2) (providers) | Is synthetic output marked in a machine-readable way? | Nowhere. | A record line is not a marking on the output. |
| EU AI Act, Art. 50(3) (deployers) | Emotion recognition or biometric categorisation: are people told? | Out of scope. | Says nothing. |
| EU AI Act, Art. 50(4) (deployers) | Text published to inform the public "on matters of public interest": is it disclosed, or did it pass "a process of human review or editorial control"? (wording as fetched in the study's Round 3: R1 file L338, R2 file L334-336) | Rule 3 records which AI helped and which person reviewed: the facts needed to judge the exception. | It does not decide whether the exception applies, or whether the adopter is a provider or a deployer. |
| NIST AI RMF 1.0, GOVERN 1 and 2 | Are policies in place and transparent? Who is accountable? | Rule 4: an owner and a source on every rule. Rule 6: the organization's rule quoted. Rule 3: a named reviewer and who can stop. | Training, resourcing, and practice across a whole organization. |
| NIST AI RMF 1.0, GOVERN 6; MANAGE 3 | Third-party software, data and supply chain? | Rule 3 names the AI maker and model, and says when every reader came from one maker. | Any assessment of the supplier. |
| NIST AI RMF 1.0, MAP 5 | Impacts on individuals, groups and communities characterised? | Only the opening question and Rule 1. | A one-line question is not a characterisation. |
| NIST AI RMF 1.0, MEASURE 1 and 2 | Methods applied; the system evaluated? | Rule 5: checks that can fail, tried by another hand. | Measures of validity, bias, robustness or security. |
| NIST AI RMF 1.0, MANAGE 4 | Response, recovery, communication? | Rule 2: errors recorded and corrected by new record. Rule 3: a stop before what cannot be undone. | An incident plan or a way to tell affected people. |
| ISO/IEC 42001:2023, 5.2 and A.2.2 | Is there an AI policy? | Rule 6, when the adopter is the organization: its policy is the quoted text. | Leadership commitment. |
| ISO/IEC 42001:2023, 5.3 and A.3.2 | Roles, responsibilities, authorities? | Rule 4 (owners) and Rule 3 (reviewer, who can stop). | Authority to act beyond the record. |
| ISO/IEC 42001:2023, 6.1.4 and A.5.2 to A.5.4 | AI system impact assessment? | Only the opening question and Rule 1. | Any assessment process. |
| ISO/IEC 42001:2023, A.6.2.8; 10.2 | Event logs; nonconformity and corrective action? | Rule 2: a record, corrected by adding. | Root-cause analysis. |
| ISO/IEC 42001:2023, 9.1 | Monitoring and evaluation? | Rule 5. | What is monitored, and how often. |
| ISO/IEC 42001:2023, A.7.5; A.8; A.10.3 | Data provenance; information for interested parties; suppliers? | Rule 2 (copies with origin), Rule 3 (who helped), Rule 8 (rules the affected can read). | A supplier process; a way for outsiders to report harm. |

Not answered anywhere: management review, objectives, competence, the scope of a management system, security,
and certification.

## Honest limits

Each limit is a concern, not a measured risk. Each has the test that would show it is wrong.

1. **The by-hand privacy check will miss things.** Even the study's best rebuilt scanner found 7 of 12 facts
   planted by another hand (paper section 5a, item 1). *Shown wrong if:* a by-hand list catches every fact in a
   sealed set planted by someone else.
2. **The record can still be lost.** Rule 2 asks for a second copy, but says nothing of how far away, or how
   often. *Shown wrong if:* a real adopter's record survives the loss of one machine or one account.
3. **One maker's models drafted, judged and merged this.** Three pairs of runs of one AI model wrote the drafts;
   two blind judges, both from the same maker, ranked them; one more run of that model merged them (paper:T7).
   *Shown wrong if:* a person or another maker's model reads it and finds what this draft found, and nothing it
   missed.
4. **One person can still hold every stop.** Rule 3 makes that visible; it does not spread it (paper:T4). *Shown
   wrong if:* an adopter's HEAD line names two people with authority over one stop.
5. **Rule 7 has never met a real disagreement.** The study holds no recorded case of an organization deciding
   against a person (paper:F6, paper:W1), and none where an organization's requirement met Rule 1. The default may
   be wrong in the first real case. *Shown wrong if:* a real recorded meeting where both sides accept the default's
   result.
6. **The checks read the record, not the behaviour.** An AI system may not follow the rules it is given
   (paper:T6), and one test request under Rule 3 shows one stop, once. *Shown wrong if:* a blind comparison, with
   and without these rules, shows fewer faults with them.
7. **Owner fields are for people, not for better AI output.** In the study, saying whose a rule is added nothing
   beyond saying the rule concretely (paper:W7). *Shown wrong if:* an outside test with many tasks shows owned
   rules beating plain, specific ones.
8. **No command line means no fingerprints for many groups.** Date-and-source is weaker. *Shown wrong if:* such a
   group makes and compares fingerprints with tools it already has.
9. **The crosswalk is one reader's.** *Shown wrong if:* a second reader's mapping agrees row by row.
10. **The two checkers check the form, not the truth.** They can show that every rule has an owner, a check that
    names its RED and NOT CHECKED, reasons with evidence that resolves, and a falsifier. They cannot show that a
    check is good, that evidence says what the rule claims, or that a quote cut at a word keeps its meaning. Four
    other runs of the same AI model wrote the 50 outside plants run on them; 46 apply to this form, and both
    checkers caught 38 of the 45 faults and passed the one control. The consolidator read every plant before
    writing the checkers, so none was blind (`PLANTS-others.tsv`). *Shown wrong if:* a person or another maker's
    model plants sealed faults and every one is caught.
11. **The checkers are tied to this study's files.** They carry their own fingerprints of the eight sources below,
    so a forged copy cannot vouch for itself. An adopter must give their own (`--pins`) or remove this study's
    Sources table; until then their evidence reads RED or NOT CHECKED, never OK. *Shown wrong if:* an adopter
    runs the check on their own copy with no change to the checker and gets a true OK.
12. **English only, for now.** The words were chosen to translate, but no translation exists. *Shown wrong if:* a
    translated copy, with its record, is used by a group.
13. **The law exit in Rule 1 is the easiest one to claim.** Naming the law and quoting its words lets a reader
    check a claim; it does not make the claim right, and a hurried reader may not check. *Shown wrong if:* a review
    of an adopter's HELD lines finds every quoted law real, found where it says, and on point.
14. **Hidden characters are shown, not judged.** The checkers mark invisible and direction-changing characters as
    a NOTE and never as RED, so that a correctly written right-to-left text passes. A word hidden that way in prose
    passes too, with a NOTE. *Shown wrong if:* a set of such characters is found that no correctly written text in
    any script needs, so they could be RED without failing anyone.
15. **Rule 3 holds two ideas.** Saying who helped and stopping before what cannot be undone share one rule and one
    check here; two of the three drafts kept them as two rules. *Shown wrong if:* readers given the core act on
    both halves as often as on any one-idea rule.

## From the baseline

The baseline is `operating-model-BASE.md` 1.0.51 (sha256 `3c8db5aa…`, 315 lines). Every paragraph of it is listed
below, either kept or left out.

### Kept

- BASE L13-15 · one self-contained file · in: form; this model is one file
- BASE L17-18 · a baseline to derive from, the host's own rules first · in: Start step 3 and Rule 6
- BASE L27-30 · state the guess before trying, recorded before the attempt · in: Rule 5, as the expected answer
  written before each run (row1:N11)
- BASE L50-54 · validate before returning · in: Rule 5, reworded as "say what failed" (row1:BA-14)
- BASE L89-91 · receipt at the turns · in: the Evidence line of every Why block
- BASE L163-166 · absent is not zero · in: the three answers (the rest of that paragraph is left out, below)
- BASE L189-192 · outside-in grounding · in: Rule 6, the organization's own written rule first, quoted (row1:BA-44)
- BASE L194-197 · organization, then person, then default · in: Rule 7, as a declared default with its other choice
- BASE L204-206 · record the error; name who checks · in: Rule 2 and Rule 5
- BASE L211-212 · keep the difference speakable · in: Rule 4; a writer's reading is marked as the writer's
- BASE L214-221 · record by default; minimum necessary at the share boundary · in: Rule 2 and Rule 1
- BASE L223-224 · say so out loud when something wants care · in: Rule 1; a refusal names the field and reason
- BASE L226-230 · verification and the honesty floor · in: Rule 5, and Rule 3 for who read it
- BASE L251-253 · the methods are offered, not forced · in: Start step 4; keep, rewrite or drop each rule
- BASE L255-258 · understanding hard things is creating access · in: Rule 8
- BASE L260-262 · lead with the substance · in: form; the rules first, their reasons and history after
- BASE L264-266 · a tight anchor at the head · in: the head; Owner, Licence, Version, Fingerprint
- BASE L268-271 · change management; records supersede by new record · in: Rule 2
- BASE L273-274 · the bar: would a reviewer say you cannot do that to the people you serve · in: the opening question
- BASE L280-282 · identity by fingerprint · in: the head and Rule 2
- BASE L284-285 · three parts working, two released · in: the head (Version)
- BASE L306-309 · adopt by content · in: Rule 2; keep the old copy and check the fingerprint
- BASE L313-315 · licence and credit line · in: the foot, word for word

### Left out, and why

- BASE L8-11 · the method is the called shot · why: as a whole method it answers none of the four questions, and
  its practice at home was not shown (paper:F7, paper:W6). Its first beat, the guess written down before trying,
  held in row 2 (R2S-010) and is kept inside Rule 5. Add the rest as your own rule.
- BASE L24-25 · the four-beat loop, whose product is the delta · why: as above.
- BASE L32-37 · try, test, write · why: as above; "write" lives on in Rule 2.
- BASE L39-42 · two rails, counting and judgement · why: a measuring idea the four questions do not need; its
  wording was changed once with no record (row1:BA-09).
- BASE L44-48 · announce at the beats; no hand edits between beats · why: they serve the loop, which is left out.
- BASE L56-58 · passthrough · why: eight small rules can stay on, each binding only what it covers; there is no
  heavy method to switch off.
- BASE L60-63 · read it all once more · why: good practice with no check that could fail as written.
- BASE L69-87 · the lens: change and learning, opposition built, a risky assumption · why: the source shop's own
  vocabulary; its letter mapping is an open reading (row1:BA-42).
- BASE L97-114 · piles, boulders and mountains · why: a way to sort work, not a way to record whose rule.
- BASE L118-142 · measures: tag kinds, volume, proof-pairs, fences, deference · why: this model prices nothing, so
  it needs no measuring discipline. Anyone who measures should take that part whole.
- BASE L148-161 · nothing is called a risk until measured; two factors; concerns · why: this model makes no risk
  claims, and its limits are written as concerns.
- BASE L163-166 · ordinals do not multiply; count is not severity · why: no numbers are priced here.
- BASE L168-175 · a band, and the ordinal bottom rung · why: risk pricing, left out with the part above; the band
  as built could never fire (row1:RC-11).
- BASE L177-183 · the bearing ratio · why: the source shop's own vocabulary; its scale is not declared
  (row1:BA-43).
- BASE L196-197 · naming an opening matters as much as flagging a hazard · why: a stance worth keeping, with no
  check; its wording differs from its source (row1:BA-47).
- BASE L199-203 · behaviours earned by a host value; question before you solve · why: manner, not checkable as
  written; the two-pass form first needs a recorded seed, an other choice kept on file and a condition to change
  it (row1:O09).
- BASE L207-210 · do not abandon the problem; transparent and still arguing · why: good stances with no check
  that could fail as written.
- BASE L232-238 · the ordering: do no harm, demand productivity, review the instructions · why: it ranks tools
  second only to harm avoidance, against the source shop's own first value, and the question is open
  (row1:BA-60, row1:BA-61). A stranger's model should not carry one shop's order.
- BASE L240-243 · the wind-down budget · why: its numbers were invented and labelled so (row1:BA-62,
  row1:BA-63); not needed here.
- BASE L245-249 · choosing cases without cherry-picking · why: a sampling method, and its "discard the middle"
  half is contested (row1:BA-64).
- BASE L295-298 · which direction the versions will take · why: history, not a rule.
- BASE L300-304 · what 1.0.51 folds in · why: history; it belongs in the change record.

## Sources

R2S and R3S ids are sections of the row-2 and row-3 scores. Paper ids are items (F, S, W, O, T) and sections
(sec5a) of the Act I paper. Row1 ids are rows of the agreed table, the contested table, or the list of new ideas.
`model-check.sh` and `model_check.py` resolve every id against these files and check each fingerprint, against
this table and against their own copy of it.

| name | path | sha256 |
|---|---|---|
| score | turn-2026-09-30/act2/r2/SCORE-2026-09-30-row-2-decisions.md | 49969c6936c84d54faa42706dc5557df956f6bc15dacb739dedff4e80a05210d |
| score3 | turn-2026-09-30/act2/r3/SCORE-2026-09-30-row-3.md | 95dd05bda313de98060d6d382219a8df39e55c83649fe483da24d6640ca938fe |
| paper | turn-2026-09-30/PAPER-2026-09-30-act-1-bringing-the-review-home.md | 034f8694b13f1fe4dfde62d82b52833bf5d9ca8d7394c7bf72b5556f9ccf8028 |
| row1-conclusive | turn-2026-09-30/act2/ROW1-CONCLUSIVE.tsv | 0ddc250fd2f386e71d2647c284d9da0ce900c29141365c7a3969f5292e2116fb |
| row1-contested | turn-2026-09-30/act2/ROW1-CONTESTED.tsv | 789d435f02f473414c876ee0bdbe600fb099b360e6c60a1daf8d01cf9ca6b965 |
| new-ideas | turn-2026-09-30/act2/NEW-IDEAS.tsv | c02902dd2ae16c8464072d68b0a603b4199f197ee123da3a4d38542677a14794 |
| org-rule | turn-2026-09-30/act1/r2/P5B/fetched/AGENTS.md.github | 8f42a69a689ba1c4138471815ebcb995820698bec2d025e90f09464fef18b7b5 |
| base | operating-model-BASE.md | 3c8db5aa2e9ead287632b0bf3ef5bad67d90d984088fe8492cda238330095235 |

---

Assisted-by: Claude (Anthropic), model claude-opus-5-5: three pairs of runs wrote the drafts, and one run merged
them, following the keep and drop lines of two blind judges. Reviewed by: no person yet.

*© 2026 Corwin Brust — this work is licensed CC BY 4.0; please retain attribution
to Corwin Brust. Developed and tested with the help of Bryant Frankford and B.K. Graphics (bkgraphics.com),
with thanks.*
