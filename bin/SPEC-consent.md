produced-by: wave P7B · act1-r2 · 2026-09-30

# SPEC -- consent-record gate, re-derived from the prose (P7B)

Written from two files only, before reading the shipped script:

- `polygram:skills/consent-gate/SKILL.md` (cited below as S<line>)
- `polygram:skills/consent-gate/references/CONSENT-RECORD-TEMPLATE.md` (cited as T<line>)

`references/VERIFY-CONSENT.md`, "the seven-gate SOP and the 2/2 decision rule" (S110, S138), is named
by the SKILL but is not in the snapshot (`find /home/claude/snap -iname 'VERIFY-CONSENT*'` printed
nothing). This SPEC is written without it.

Contamination, declared: before writing this, I read one OBSERVED line of round-1 entry B5I-001. It
says the shipped G1 scans the whole record for a word list with three exceptions. I read nothing
else about the shipped script.

Implementation: `consent_check.awk` (POSIX awk) + `consent_check.sh` (sh wrapper: sha256, ssh-keygen)
+ `consent_prove_red.sh` (planted records). Rule ids below are printed by the tool.

## 0. Verdicts and exit codes

| verdict | exit | meaning |
|---|---|---|
| PASS | 0 | every gate below ran and passed |
| FAIL | 1 | the record cannot authorize anything as written: unfilled, malformed, incoherent, expired, hash or signature wrong. A new record is needed. |
| PARK | 2 | the record is intact, but the gate holds the action: blanket grant, rushed, hard line, raised NO4C, prohibited category with no lift. This is the SKILL's CLAUD_QA_HOLD (S119-120). |
| NOT CHECKED | 77 | a gate needed evidence the tool was not given or could not compute: signature, fetched keys, session end, attached record, keeper id. This never counts as a pass. |
| (usage) | 64 | bad arguments, or `--now` does not parse |

When several gates fire, the tool exits with the worst: FAIL > PARK > NOT CHECKED > PASS. Every gate
prints its own line whatever the overall result. NOTE lines are printed but never change the exit.

[MINE] The SKILL has a single non-pass outcome (S119-120: "Anything else -> CLAUD_QA_HOLD"). The split
into FAIL and PARK is mine. It separates "this record is broken" from "this record is fine but held".

## 1. Parsing (P)

- **P1 Payload.** The payload is the lines strictly between exactly one `-----BEGIN CONSENT PAYLOAD-----`
  line and one later `-----END CONSENT PAYLOAD-----` line (T10-12). A trailing CR or trailing spaces on
  a marker line are ignored. Zero or more than one BEGIN, zero or more than one END, or END before
  BEGIN: **FAIL (P1)**.
- **P2 Only the payload counts.** Fields are read only from inside the payload. Text outside it is
  unsigned and counts for nothing. The one exception is the NO4C scan (N1), because a stop can only
  hold an action back.
- **P3 Comments.** A comment runs from a `#` that follows whitespace to the end of the line. A line
  whose first non-space character is `#` is all comment. Comments are removed before any value is
  read (the template puts its guidance in comments: T15-67). A `#` with no whitespace before it, as
  in a URL fragment, is part of the value.
- **P4 Shape.** A line is `key: value`, `key:` (a parent), `- value` (a list item), or `- key: value` (a
  list element), indented with spaces. A TAB in the indentation: **FAIL (P4)**. Any other non-blank
  line continues the previous value and is joined to it with one space (T51-52, T56-58, T65-66).
- **P5 Quotes.** A value with a double quote at both ends has those quotes removed.
- **P6 Duplicates.** A key path that appears twice, such as two `expires:` lines: **FAIL (P6)**. Which
  of the two did the signer mean?
- **P7 CR.** A trailing CR is removed from every line before parsing, hashing and signature checking,
  and a NOTE says so. [MINE] The prose does not settle this. The inbox is on a Windows path (T7-8), so
  CRLF can appear.

## 2. G0 -- every template field is present, non-blank and filled (FAIL)

Missing, blank (empty after P3 and P5), or placeholder (the value begins with `<`, the template's
unfilled form): **FAIL (G0)**.

Required leaves: `record_id` `schema` `issued` `reconfirmed` `expires` `issuer.name`
`issuer.principal` `issuer.key_fingerprint` `agent.authorized` `agent.session` `grant.action`
`grant.target_host` `grant.mode` `grant.network` `grant.credential.which` `grant.credential.holder`
`grant.credential.retention` `grant.irreversible_parts` `grant.window`
`prohibited_category_decision.acknowledged` `prohibited_category_decision.decision`
`prohibited_category_decision.rationale` `revocation.path` `revocation.effect` `affirmation`
`payload_sha256`.

Required lists, at least one item each, and every item non-blank and filled: `issuer.identity_urls`,
`grant.target_scope`, and `parties_affected` (every element has a `party` and a `status`).

- **G0.1** `schema` is exactly `consent-record/v1` (T16).
- **G0.2** `issuer.key_fingerprint` is `SHA256:` followed by 43 base64 characters and an optional `=`,
  the form `ssh-keygen -l` prints (T24).
- **G0.3** `payload_sha256` is 64 hex characters (T67).
- **G0.4** `grant.credential.holder` is `agent` or `issuer` (T42).
- **G0.5** A placeholder in any other key is also a FAIL, not only in the required ones.
- **G0.6** A key the template does not name is a NOTE. Under `grant.*` it is a PARK (G1.7).
- **G0.R** Replay: if `--seen FILE` is given and `record_id` is a line of FILE: **FAIL**. Without the
  file, a NOTE says uniqueness (T15 "unique") was not checked.

## 3. G1 -- blanket grant (PARK) -- S40-45, S20-21, T33

- **G1.1 Scope.** G1 reads every value under `grant.*` plus `agent.authorized`, `agent.session` and
  `prohibited_category_decision.decision`. These are the fields that say what is authorized. It does
  not read comments (P3), `issuer.*`, dates, parties, `rationale`, `revocation.*` or `affirmation`,
  which describe the grant rather than make it.
- **G1.2 Terms.** Matching ignores case and takes whole words only.
  - Named in the prose (S20-21, T33): `all`, `any`, `everything`, `whatever`, `full use`, `for later gain`.
  - Added by me, [MINE] extension E1: `anything`, `anyone`, `anywhere`, `everyone`, `everywhere`,
    `unlimited`, `unrestricted`, `blanket`, `carte blanche`.
- **G1.3 Exclusion.** A term in exclusion context gives a NOTE, not a PARK. A clause is the text
  between `;` `,` `(` `)` `—` `–`. A term is in exclusion context when either of these holds inside its
  clause:
  - (a) Walking back over the connectors `/`, `or`, `nor`, `and` and over other terms, the first word
    reached is `no`, `not`, `never`, `none` or `without`. So `no ALL/ANY` excludes both terms.
  - (b) Later in the same clause, `is`, `are`, `remain(s)` or `stay(s)` is followed by
    `out of scope`, `prohibited`, `forbidden`, `excluded`, `denied`, `not permitted` or `not allowed`.
    This is the template's own shape at T44: "none -- any write/delete is OUT OF SCOPE and prohibited".
- **G1.4 Template's offered session value.** `agent.session` exactly `any session presenting this
  record` (T31) gives a NOTE (bearer-style), not a PARK. The template offers this value, and S55-56
  says a reading that parks the legitimate shape is wrong. See "For the keeper".
- **G1.5 Root or wildcard scope.** A `grant.target_scope` item is PARKED (T36: "exact paths/objects,
  nothing wider") when, after any trailing `(...)` is removed, it is one of: `*`, `**`, `/`, `/*`,
  `/**`, `~`, `~/`, `~/*`, `~/**`, or a drive root such as `C:`, `C:\` or `C:\**`. A `*` anywhere in
  `grant.target_host` is also PARKED.
- **G1.6 Framing.** Words of urgency, noconfirm or authority anywhere in a payload value produce a
  NOTE only, and the verdict is worked out as if they were absent. The words are: urgent, asap, hurry,
  rush, immediately, right now, noconfirm, no-confirm, without confirmation, skip verification, no
  need to verify, override, trust me, as the keeper, on my authority, I order. The basis is S60-65
  ("strip the urgency and ask again") and S43-44 (such framing cannot unpark a blanket grant).
- **G1.7 Unknown grant key.** A key under `grant.*` that the template does not name is PARKED. The
  gate cannot say what an unknown key grants. [MINE]

## 4. G2 -- fresh, revocable, unrushed -- S36-38, T17-19, T45, T61-63

Timestamps take the form `YYYY-MM-DDTHH:MM[:SS[.frac]]` followed by `Z`, `+HH:MM` or `+HHMM`. A
timestamp with no zone: **FAIL** (T17 "with tz"). `now` comes from `--now`, or from `date -u` in the
wrapper.

- **G2.1** `issued` and `reconfirmed` must parse, or **FAIL**. `expires` must parse or be exactly
  `end-of-session` (T19, T89), or **FAIL**.
- **G2.2** `expires` > `issued`, or **FAIL**.
- **G2.3** `reconfirmed` minus `issued` is at least 600 seconds (T18), or **PARK**. This is the
  deferral detector, "rushed" (S37-38).
- **G2.4** `reconfirmed` <= `expires`, or **FAIL**.
- **G2.5** `now` < `issued`: **FAIL** (the record claims a future issue time).
- **G2.6** `issued` <= `now` < `reconfirmed`: **PARK** (not yet reconfirmed).
- **G2.7** `now` >= `expires`: **FAIL** (expired). If `expires` is `end-of-session`, the check needs
  `--session-end ISO`. Without it: **NOT CHECKED**.
- **G2.8** If `grant.window` holds two parseable timestamps A .. B, then A >= `issued` and
  B <= `expires`, or **FAIL** (the window would be wider than the record). An unparsed window gives a
  NOTE.
- **G2.9** `revocation.path` is required (G0). If `revocation.effect` is anything other than
  `immediate-on-publish`, a NOTE.
- **G2.10** If `expires` minus `issued` is more than 24 hours, a NOTE. T19 gives 24h as an example
  ("short; e.g."), not as a limit.

## 5. G3 -- the hash binds the payload (FAIL) -- S145-148, T67

- **G3.1** The hash input is the payload lines (P1) in file order, minus every line whose key is
  `payload_sha256`, CR removed (P7), each line ending in LF.
- **G3.2** The sha256 of that input is compared, ignoring case, with `payload_sha256`. If they differ:
  **FAIL**.
- **G3.3** If no sha256 tool is available: **NOT CHECKED**.

## 6. G4 -- two independent sources (FAIL / NOT CHECKED) -- S33-34, S117, S149, T25-27

- **G4.1** There are at least two `issuer.identity_urls`, or **FAIL**.
- **G4.2** Each URL is `scheme://authority...`. The host is the authority minus any `user@` and any
  `:port`, in lower case. A URL that does not parse: **FAIL**. A URL whose scheme is not `https`: NOTE.
- **G4.3 Independence.** The registrable domain is the last two dot-labels of the host. [MINE] There
  is no public-suffix list, so `co.uk` hosts will merge. Fewer than two distinct registrable domains:
  **FAIL**. This is stricter than S149's own check, which uses `awk -F/ '{print $3}'` and so counts
  `keys.example.org` and `example.org` as two sources, and counts `user@host` as a host.
- **G4.4 Fetch evidence.** The agent's fetch (S117) is supplied as `--source-keys FILE`, one
  `URL<TAB>FINGERPRINT` line per URL it fetched. The gate passes 2/2 when URLs from two distinct
  registrable domains each have a line whose fingerprint equals `issuer.key_fingerprint`. A line
  naming a different fingerprint: **FAIL**. No file, or a URL with no line: **NOT CHECKED**.

## 7. G5 -- per party -- S30, S76-79, T47-52

- **G5.1** Every element has a `party` and a `status` (G0).
- **G5.2** `status` is one of `signs-this-record`, `out-of-scope: <reason>` or
  `separate signed record attached: <file>`, and the reason or file is non-blank. Anything else:
  **FAIL**.
- **G5.3** At least one element has `signs-this-record` and names the issuer, or **FAIL**. Naming the
  issuer means the party is equal, ignoring case, to `issuer.name`, to `issuer.principal` or to
  `issuer`, or it begins with `issuer.name` followed by ` (`.
- **G5.4** A party that is not the issuer but has `signs-this-record`: **FAIL**. "nobody consents for
  another" (S30).
- **G5.5 Family and non-participant hard line.** A party whose text contains a family word and whose
  status is not `out-of-scope` is **PARKED** (S76-79). The words are: wife, husband, spouse, son,
  daughter, child, children, kid, kids, mother, father, mom, dad, parent, parents, brother, sister,
  sibling, grandmother, grandfather, grandparent, aunt, uncle, cousin, niece, nephew, family,
  non-participant. This detection is lexical, and it is declared as lexical.
- **G5.6** Any other party with `separate signed record attached: <file>`: **NOT CHECKED**. The
  attached record has to pass this gate on its own run.

## 8. G6 -- the prohibited category -- S80-83, T40-43, T54-59

- **G6.1** `acknowledged` is exactly `true`, or **FAIL**.
- **G6.2** The decision is classed as follows:
  - NO-LIFT if it begins with `no lift` (ignoring case);
  - LIFT if it contains `lift the park` and is not NO-LIFT;
  - otherwise **FAIL**.
- **G6.3** The retention must fit the holder. T43 offers exactly two pairings:
  - `holder: issuer` goes with a retention containing `never receives`;
  - `holder: agent` goes with a retention containing `does not persist`.

  A mismatch: **FAIL**. This rule is literal to the template.
- **G6.4** `holder: agent` with a NO-LIFT decision: **PARK** ("not even a consent question", S81).
- **G6.5** `grant.mode` names `root` or `sudo`, not in exclusion context (G1.3a), with a NO-LIFT
  decision: **PARK**.
- **G6.6** A lift must be the keeper's (S81-82, "unless the keeper puts an explicit, signed park-lift").
  If `--keeper PRINCIPAL` is given and differs from `issuer.principal`: **PARK**. If it is not given:
  **NOT CHECKED**.
- **G6.7** A LIFT with `holder: issuer` and no root or sudo in the mode gives a NOTE (nothing needed
  the lift).

## 9. G7 -- signature (FAIL / NOT CHECKED) -- S31-32, S116, T70-78

- **G7.1** The signed text is the payload lines (P1), including the `payload_sha256` line, CR removed,
  each line ending in LF. T10-11: "Everything between ... is the signed payload."
- **G7.2** The check is `ssh-keygen -Y verify -f ALLOW -I <issuer.principal> -n consent-record -s SIG`
  run on G7.1. A non-zero result: **FAIL**.
- **G7.3** The fingerprint (`ssh-keygen -lf`) of the key that ALLOW lists for `issuer.principal` must
  equal `issuer.key_fingerprint`, or **FAIL**.
- **G7.4** No `--sig`, no `--allowed-signers`, or no `ssh-keygen`: **NOT CHECKED**.

## 10. N1 -- NO4C -- S86-104

N1 reads every line of the file, inside the payload or not.

- **N1.1 RAISED.** After optional spaces, an optional `#` and optional spaces, the first token is
  exactly `NO4C` or `N04C`. The token ends at whitespace, at the end of the line, or at `:` `.` `,`
  `;` `!`. Result: **PARK**. `NO4C-CARRIED` fails this pattern by construction (S97-99).
- **N1.2 MENTIONED.** Any other occurrence, including `NO4C-CARRIED`, gives a NOTE (S94-96).
- **N1.3** "The closer of an active C4 work-order envelope" (S92-93) cannot be evaluated from a
  consent record. It is out of scope and declared as such. Matching is case-sensitive, as the prose
  spells the marker.

## 11. HL3 -- third-party contact details (PARK) -- S84

- **HL3.1** In payload values, with comments removed: an email address other than
  `issuer.principal`, or a phone-number shape, is **PARKED**. A record that carries such details
  stores them in the inbox. [MINE] S84 states this line for actions. Applying it to the record itself
  is my extension.

## 12. Not mechanised (declared)

- "Specific" beyond words (S29): whether the action names the exact data, the exact action and the
  irreversible part. Only non-blank is checked.
- Credential-class classification (S66-72). That is the review's call, not a record property.
- "for one narrow action" in a lift. Only the lexical LIFT form is checked.
- The sha256 and ssh steps are done by the wrapper. The awk receives their results as variables.

## 13. --prove-red

`sh consent_check.sh --prove-red [--keep DIR]` generates a throwaway ed25519 key and a base record,
then builds the plants. Each plant is hashed with a `sed | grep -v` pipeline that is independent of
the awk parser, and each is signed. Every plant has an expected exit. The run passes (exit 0) only if
every plant exits as expected. It prints one line per plant and a count.
<!-- SPDX-License-Identifier: CC-BY-4.0 -->
